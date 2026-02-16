package com.boiaro.app.readium

import android.app.AlertDialog
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.SeekBar
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.boiaro.app.R
import androidx.browser.customtabs.CustomTabsIntent
import androidx.fragment.app.commitNow
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import java.io.File
import java.io.FileOutputStream
import java.net.URL
import kotlin.math.abs
import kotlin.math.roundToInt
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import org.readium.r2.navigator.epub.EpubNavigatorFactory
import org.readium.r2.navigator.epub.EpubNavigatorFragment
import org.readium.r2.navigator.epub.EpubPreferences
import org.readium.r2.navigator.preferences.Theme
import org.readium.r2.shared.ExperimentalReadiumApi
import org.readium.r2.shared.publication.Link
import org.readium.r2.shared.publication.Locator
import org.readium.r2.shared.publication.Publication
import org.readium.r2.shared.publication.allAreHtml
import org.readium.r2.shared.publication.services.positionsByReadingOrder
import org.readium.r2.shared.util.AbsoluteUrl
import org.readium.r2.shared.util.asset.AssetRetriever
import org.readium.r2.shared.util.getOrElse
import org.readium.r2.shared.util.http.DefaultHttpClient
import org.readium.r2.streamer.PublicationOpener
import org.readium.r2.streamer.parser.DefaultPublicationParser

@OptIn(ExperimentalReadiumApi::class)
class ReadiumReaderActivity : AppCompatActivity(), EpubNavigatorFragment.Listener {

    private data class TocItem(val title: String, val locator: Locator)

    private lateinit var titleText: TextView
    private lateinit var loadingContainer: FrameLayout
    private lateinit var readerContainer: FrameLayout
    private lateinit var bottomControls: View
    private lateinit var progressText: TextView
    private lateinit var chapterText: TextView
    private lateinit var progressSeekBar: SeekBar
    private lateinit var previousButton: Button
    private lateinit var nextButton: Button
    private lateinit var tocButton: Button
    private lateinit var bookmarkButton: Button
    private lateinit var fontDecreaseButton: Button
    private lateinit var fontIncreaseButton: Button
    private lateinit var themeToggleButton: Button

    private val httpClient = DefaultHttpClient()
    private val assetRetriever by lazy { AssetRetriever(contentResolver, httpClient) }
    private val publicationOpener by lazy {
        PublicationOpener(
            publicationParser = DefaultPublicationParser(
                context = this,
                assetRetriever = assetRetriever,
                httpClient = httpClient,
                pdfFactory = null
            )
        )
    }

    private var publication: Publication? = null
    private var navigator: EpubNavigatorFragment? = null
    private var locatorPositions: List<Locator> = emptyList()
    private var currentLocator: Locator? = null
    private var bookmarks: MutableList<Locator> = mutableListOf()
    private var currentPreferences = EpubPreferences(fontSize = 1.0, theme = Theme.LIGHT)
    private var isSeekingProgrammatically = false

    private lateinit var epubPath: String
    private lateinit var bookTitle: String
    private lateinit var bookId: String

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_readium_reader)

        epubPath = intent.getStringExtra(EXTRA_EPUB_PATH).orEmpty()
        bookTitle = intent.getStringExtra(EXTRA_BOOK_TITLE).orEmpty().ifBlank { "Reader" }
        bookId = intent.getStringExtra(EXTRA_BOOK_ID).orEmpty().ifBlank { epubPath }
        bookmarks = loadBookmarks()

        bindViews()
        bindUiActions()
        openPublication()
    }

    private fun bindViews() {
        titleText = findViewById(R.id.titleText)
        loadingContainer = findViewById(R.id.loadingContainer)
        readerContainer = findViewById(R.id.readerContainer)
        bottomControls = findViewById(R.id.bottomControls)
        progressText = findViewById(R.id.progressText)
        chapterText = findViewById(R.id.chapterText)
        progressSeekBar = findViewById(R.id.progressSeekBar)
        previousButton = findViewById(R.id.previousButton)
        nextButton = findViewById(R.id.nextButton)
        tocButton = findViewById(R.id.tocButton)
        bookmarkButton = findViewById(R.id.bookmarkButton)
        fontDecreaseButton = findViewById(R.id.fontDecreaseButton)
        fontIncreaseButton = findViewById(R.id.fontIncreaseButton)
        themeToggleButton = findViewById(R.id.themeToggleButton)

        titleText.text = bookTitle
        findViewById<ImageButton>(R.id.backButton).setOnClickListener { finish() }
        updateBookmarkButton()
    }

    private fun bindUiActions() {
        updateThemeButtonLabel(currentPreferences.theme ?: Theme.LIGHT)

        previousButton.setOnClickListener {
            navigator?.goBackward(animated = true)
        }

        nextButton.setOnClickListener {
            navigator?.goForward(animated = true)
        }

        tocButton.setOnClickListener {
            showTableOfContentsDialog()
        }

        bookmarkButton.setOnClickListener {
            toggleBookmark()
        }

        fontDecreaseButton.setOnClickListener {
            val current = currentPreferences.fontSize ?: 1.0
            val next = (current - 0.1).coerceAtLeast(0.8)
            currentPreferences = currentPreferences.copy(fontSize = next)
            navigator?.submitPreferences(currentPreferences)
        }

        fontIncreaseButton.setOnClickListener {
            val current = currentPreferences.fontSize ?: 1.0
            val next = (current + 0.1).coerceAtMost(2.5)
            currentPreferences = currentPreferences.copy(fontSize = next)
            navigator?.submitPreferences(currentPreferences)
        }

        themeToggleButton.setOnClickListener {
            val nextTheme = when (currentPreferences.theme ?: Theme.LIGHT) {
                Theme.LIGHT -> Theme.SEPIA
                Theme.SEPIA -> Theme.DARK
                Theme.DARK -> Theme.LIGHT
            }
            currentPreferences = currentPreferences.copy(theme = nextTheme)
            navigator?.submitPreferences(currentPreferences)
            updateThemeButtonLabel(nextTheme)
        }

        progressSeekBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar, progress: Int, fromUser: Boolean) = Unit

            override fun onStartTrackingTouch(seekBar: SeekBar) = Unit

            override fun onStopTrackingTouch(seekBar: SeekBar) {
                if (isSeekingProgrammatically || locatorPositions.isEmpty()) {
                    return
                }

                val ratio = seekBar.progress.toDouble() / seekBar.max.toDouble()
                val targetIndex = (ratio * (locatorPositions.size - 1)).roundToInt()
                    .coerceIn(0, locatorPositions.size - 1)
                navigator?.go(locatorPositions[targetIndex], animated = true)
            }
        })
    }

    private fun openPublication() {
        if (epubPath.isBlank()) {
            handleFatalError("Invalid EPUB path.")
            return
        }

        lifecycleScope.launch {
            runCatching {
                val file = prepareLocalEpubFile(epubPath)
                if (!file.exists()) {
                    error("EPUB file not found.")
                }
                val asset = assetRetriever.retrieve(file).getOrElse {
                    error("Unable to read EPUB asset: ${it.message}")
                }

                val openedPublication = publicationOpener.open(asset, allowUserInteraction = true).getOrElse {
                    error("Unable to open EPUB publication: ${it.message}")
                }

                val isSupportedEpub =
                    openedPublication.conformsTo(Publication.Profile.EPUB) || openedPublication.readingOrder.allAreHtml
                if (!isSupportedEpub) {
                    error("The selected file is not a supported EPUB.")
                }

                val positions = openedPublication.positionsByReadingOrder().flatten()
                Triple(openedPublication, positions, loadSavedLocator())
            }.onSuccess { (openedPublication, positions, savedLocator) ->
                publication = openedPublication
                locatorPositions = positions
                attachNavigator(openedPublication, savedLocator)
            }.onFailure { throwable ->
                handleFatalError(throwable.message ?: "Failed to open EPUB reader.")
            }
        }
    }

    private suspend fun prepareLocalEpubFile(source: String): File = withContext(Dispatchers.IO) {
        if (source.startsWith("http://") || source.startsWith("https://")) {
            val targetFile = File(cacheDir, "readium_${source.hashCode()}.epub")
            URL(source).openStream().use { input ->
                FileOutputStream(targetFile).use { output ->
                    input.copyTo(output)
                }
            }
            return@withContext targetFile
        }

        if (source.startsWith("content://")) {
            val uri = Uri.parse(source)
            val targetFile = File(cacheDir, "readium_${source.hashCode()}.epub")
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(targetFile).use { output ->
                    input.copyTo(output)
                }
            } ?: error("Unable to open content URI.")
            return@withContext targetFile
        }

        if (source.startsWith("file://")) {
            val uriPath = Uri.parse(source).path ?: error("Invalid file URI.")
            return@withContext File(uriPath)
        }

        return@withContext File(source)
    }

    private fun attachNavigator(openedPublication: Publication, initialLocator: Locator?) {
        val navigatorFactory = EpubNavigatorFactory(openedPublication)
        supportFragmentManager.fragmentFactory = navigatorFactory.createFragmentFactory(
            initialLocator = initialLocator,
            initialPreferences = currentPreferences,
            listener = this
        )

        supportFragmentManager.commitNow {
            replace(R.id.readerContainer, EpubNavigatorFragment::class.java, Bundle())
        }

        navigator = supportFragmentManager.findFragmentById(R.id.readerContainer) as? EpubNavigatorFragment
        navigator?.let { nav ->
            lifecycleScope.launch {
                repeatOnLifecycle(androidx.lifecycle.Lifecycle.State.STARTED) {
                    nav.currentLocator.collectLatest { locator ->
                        currentLocator = locator
                        persistLocator(locator)
                        updateProgress(locator)
                        updateBookmarkButton()
                    }
                }
            }
        }

        loadingContainer.visibility = View.GONE
        readerContainer.visibility = View.VISIBLE
        bottomControls.visibility = View.VISIBLE
    }

    private fun showTableOfContentsDialog() {
        val localPublication = publication ?: return
        val tocItems = mutableListOf<TocItem>()
        collectTocItems(localPublication, localPublication.tableOfContents, tocItems)

        if (tocItems.isEmpty()) {
            Toast.makeText(this, "No table of contents found.", Toast.LENGTH_SHORT).show()
            return
        }

        val labels = tocItems.map { it.title }.toTypedArray()
        AlertDialog.Builder(this)
            .setTitle("Table of Contents")
            .setItems(labels) { _, which ->
                navigator?.go(tocItems[which].locator, true)
            }
            .setNegativeButton("Close", null)
            .show()
    }

    private fun collectTocItems(
        localPublication: Publication,
        links: List<Link>,
        target: MutableList<TocItem>,
        depth: Int = 0,
    ) {
        for (link in links) {
            val locator = localPublication.locatorFromLink(link)
            val title = link.title?.trim().orEmpty()
            if (locator != null && title.isNotEmpty()) {
                val prefix = if (depth == 0) "" else "• ".repeat(depth)
                target.add(TocItem("$prefix$title", locator))
            }
            if (link.children.isNotEmpty()) {
                collectTocItems(localPublication, link.children, target, depth + 1)
            }
        }
    }

    private fun toggleBookmark() {
        val locator = currentLocator ?: return
        val existingIndex = bookmarks.indexOfFirst { it.isSameBookmark(locator) }

        if (existingIndex >= 0) {
            bookmarks.removeAt(existingIndex)
            Toast.makeText(this, "Bookmark removed", Toast.LENGTH_SHORT).show()
        } else {
            bookmarks.add(locator)
            Toast.makeText(this, "Bookmark added", Toast.LENGTH_SHORT).show()
        }

        saveBookmarks(bookmarks)
        updateBookmarkButton()
    }

    private fun updateBookmarkButton() {
        val locator = currentLocator
        val isSaved = locator != null && bookmarks.any { it.isSameBookmark(locator) }
        bookmarkButton.text = if (isSaved) "Bookmarked" else "Bookmark"
    }

    private fun updateThemeButtonLabel(theme: Theme) {
        themeToggleButton.text = when (theme) {
            Theme.LIGHT -> "Light"
            Theme.SEPIA -> "Sepia"
            Theme.DARK -> "Dark"
        }
    }

    private fun updateProgress(locator: Locator) {
        val positionsCount = locatorPositions.size.coerceAtLeast(1)
        val position = locator.locations.position?.coerceIn(1, positionsCount)
            ?: ((locator.locations.totalProgression ?: locator.locations.progression ?: 0.0) * positionsCount)
                .roundToInt()
                .coerceIn(1, positionsCount)
        val percentage = ((position.toDouble() / positionsCount.toDouble()) * 100.0).roundToInt()

        val locatorTitle = locator.title?.takeIf { it.isNotBlank() } ?: "Chapter $position"
        chapterText.text = locatorTitle
        progressText.text = "Page $position/$positionsCount ($percentage%)"

        isSeekingProgrammatically = true
        progressSeekBar.progress = ((position.toDouble() / positionsCount.toDouble()) * progressSeekBar.max)
            .roundToInt()
            .coerceIn(0, progressSeekBar.max)
        isSeekingProgrammatically = false
    }

    private fun persistLocator(locator: Locator) {
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
            .putString(locatorPreferenceKey(), locator.toJSON().toString())
            .apply()
    }

    private fun loadSavedLocator(): Locator? {
        val rawLocator = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(locatorPreferenceKey(), null)
            ?: return null

        return runCatching {
            Locator.fromJSON(JSONObject(rawLocator))
        }.getOrNull()
    }

    private fun loadBookmarks(): MutableList<Locator> {
        val rawBookmarks = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(bookmarksPreferenceKey(), null)
            ?: return mutableListOf()

        return runCatching {
            val jsonArray = JSONArray(rawBookmarks)
            buildList {
                for (i in 0 until jsonArray.length()) {
                    val locator = Locator.fromJSON(jsonArray.optJSONObject(i))
                    if (locator != null) {
                        add(locator)
                    }
                }
            }.toMutableList()
        }.getOrDefault(mutableListOf())
    }

    private fun saveBookmarks(items: List<Locator>) {
        val jsonArray = JSONArray()
        items.forEach { jsonArray.put(it.toJSON()) }
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
            .putString(bookmarksPreferenceKey(), jsonArray.toString())
            .apply()
    }

    private fun Locator.isSameBookmark(other: Locator): Boolean {
        if (href != other.href) {
            return false
        }

        val thisProgress = locations.progression ?: locations.totalProgression ?: 0.0
        val otherProgress = other.locations.progression ?: other.locations.totalProgression ?: 0.0
        return abs(thisProgress - otherProgress) <= 0.01
    }

    private fun locatorPreferenceKey(): String = "locator_$bookId"

    private fun bookmarksPreferenceKey(): String = "bookmarks_$bookId"

    private fun handleFatalError(message: String) {
        Toast.makeText(this, message, Toast.LENGTH_LONG).show()
        finish()
    }

    override fun onExternalLinkActivated(url: AbsoluteUrl) {
        val uri = Uri.parse(url.toString())
        try {
            CustomTabsIntent.Builder().build().launchUrl(this, uri)
        } catch (_: ActivityNotFoundException) {
            startActivity(Intent(Intent.ACTION_VIEW, uri))
        }
    }

    override fun onDestroy() {
        publication?.close()
        publication = null
        super.onDestroy()
    }

    companion object {
        const val EXTRA_EPUB_PATH = "extra_epub_path"
        const val EXTRA_BOOK_TITLE = "extra_book_title"
        const val EXTRA_BOOK_ID = "extra_book_id"
        private const val PREFS_NAME = "readium_reader_prefs"
    }
}



