# Implementation Plan - Resolve SIGTRAP Crashes & fsync ANRs

This plan describes the proposed changes to address the stability issues in production affecting users on Android devices:
1. **SIGTRAP Crash in `libwebviewchromium.so`**: Caused when the underlying Chromium WebView renderer process crashes or runs out of memory, and the host application terminates because the crash is unhandled.
2. **ANR (Application Not Responding) in `[libc.so] fsync`**: Caused because progress updates write to disk (`SharedPreferences` XML) and send HTTP PUT requests immediately on every single page turn. During page flipping, this floods the platform thread with disk/network updates. When the user exits the book, Android's `QueuedWork.waitToFinish()` blocks the main thread waiting for all queued writes to be written to disk via `fsync`, triggering the ANR.

---

## Proposed Changes

### 1. Debounce Progress Syncing (Resolve fsync ANRs)
Instead of executing database writes and network synchronization on every single page turn, we will debounce these updates by **3 seconds** during reading (both for PDF and EPUB). The final/pending progress is written immediately when the user exits the reader screen or when the screen is disposed of.

#### [MODIFY] [read_book_custom_page_widget.dart](file:///d:/project/Clients/Boiaro/boiaro_app/lib/pages/home_pages/read_book_custom_page/read_book_custom_page_widget.dart)
- Add state variables to track debouncing:
  ```dart
  Timer? _progressDebounceTimer;
  int? _pendingPercentage;
  int? _pendingPage;
  int? _pendingTotalPages;
  bool _hasPendingSave = false;
  ```
- Implement `_savePendingProgress()` to perform the actual disk write (`ReadingProgressService.upsertProgress`), backend PUT request (`ProgressSyncService.saveReadingProgress`), and update session progress:
  ```dart
  Future<void> _savePendingProgress() async {
    if (!_hasPendingSave || _pendingPercentage == null || _pendingPage == null || _pendingTotalPages == null) {
      return;
    }
    _progressDebounceTimer?.cancel();
    _hasPendingSave = false;
    // Save to SharedPreferences and SUPABASE/API
  }
  ```
- Modify `_applyNativeEpubProgress(int percent, {bool force = false})` to support both immediate writing (when `force: true`) and debounced writing (when `force: false`).
- Modify the `onPageChanged.listen` listener in `_openEpubWithPlugin` to pass `force: false` to `_applyNativeEpubProgress`.
- Modify `_onPdfPageChanged` to queue page changes via the debouncer.
- Await `_savePendingProgress()` in `_handleBackPress()` to guarantee progress is saved immediately before popping the route.
- Update `dispose()` to cancel the timer and call `_savePendingProgress()` if there's a pending change.

#### [MODIFY] [ios_epub_reader_screen.dart](file:///d:/project/Clients/Boiaro/boiaro_app/lib/pages/home_pages/read_book_custom_page/ios_epub_reader_screen.dart)
- Implement debouncing for the iOS reader's `onRelocated` callback by 3 seconds to avoid spamming the backend API with PUT requests.
- Ensure pending progress is saved instantly on `dispose()`.

---

### 2. Handle WebView Renderer Termination (Resolve SIGTRAP Crashes)
We will implement `onRenderProcessGone` handler across all WebViews to prevent process termination if the renderer crashes.

#### [MODIFY] [subscription_payment_screen.dart](file:///d:/project/Clients/Boiaro/boiaro_app/lib/pages/home_pages/subscription_page/subscription_payment_screen.dart)
#### [MODIFY] [payment_screen.dart](file:///d:/project/Clients/Boiaro/boiaro_app/lib/pages/cart_pages/payment_screen.dart)
#### [MODIFY] [webview.dart](file:///d:/project/Clients/Boiaro/boiaro_app/lib/pages/home_pages/home_page/webview.dart)
- Add the `onRenderProcessGone` callback to `InAppWebView`:
  ```dart
  onRenderProcessGone: (controller, detail) async {
    debugPrint("WebView render process gone. didCrash: ${detail.didCrash}");
    try {
      await controller.reload();
    } catch (_) {}
  },
  ```

#### [MODIFY] [VisualReaderFragment.kt](file:///D:/project/Clients/Boiaro/epub_reader_kit/android/src/main/kotlin/com/example/epub_reader_kit/reader/reader/VisualReaderFragment.kt)
- Define a `SafeWebViewClient` delegator wrapper at the bottom of the file that overrides `onRenderProcessGone` to return `true` (indicating handled) and executes a callback to finish the reader activity gracefully:
  ```kotlin
  class SafeWebViewClient(
      private val delegate: android.webkit.WebViewClient,
      private val onRenderProcessGoneAction: () -> Unit
  ) : android.webkit.WebViewClient() {
      override fun onRenderProcessGone(
          view: android.webkit.WebView?,
          detail: android.webkit.RenderProcessGoneDetail?
      ): Boolean {
          onRenderProcessGoneAction()
          return true
      }
      // Delegate all other WebViewClient override methods to the `delegate` instance...
  }
  ```
- In `startMonitoringScroll()`, when a WebView is found, wrap its current WebViewClient with `SafeWebViewClient`:
  ```kotlin
  val currentClient = webView.webViewClient
  if (currentClient != null && currentClient !is SafeWebViewClient) {
      webView.webViewClient = SafeWebViewClient(currentClient) {
          activity?.finish()
      }
  }
  ```

---

## Verification Plan

### Manual Verification
1. Run compilation to verify build compiles successfully (`flutter build apk --debug`).
2. Verify visual rendering and navigation in PDF and EPUB modes.
3. Test backing out of PDF/EPUB books and check that the correct progress is preserved.
4. Verify payment WebView initialization works correctly.
