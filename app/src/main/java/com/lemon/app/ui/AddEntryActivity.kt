package com.lemon.app.ui

import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.RadioGroup
import android.widget.TextView
import android.widget.Toast
import com.google.android.material.slider.Slider
import com.google.android.material.textfield.TextInputEditText
import com.lemon.app.R
import com.lemon.app.data.VaultEntry
import com.lemon.app.data.VaultStore
import com.lemon.app.gen.PasswordGenerator
import com.lemon.app.util.SecureActivity

/**
 * Add / edit a vault entry.
 *  - password: manual text OR one-tap 32-character generator
 *  - passphrase: 1-32 dictionary words, numbered and individually editable
 */
class AddEntryActivity : SecureActivity() {

    private var editingId: String? = null
    private var type = VaultEntry.TYPE_PASSWORD

    private lateinit var panelPassword: View
    private lateinit var panelPassphrase: View
    private lateinit var inputSecret: TextInputEditText
    private lateinit var wordsLabel: TextView
    private lateinit var wordsSlider: Slider
    private lateinit var wordsContainer: LinearLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_add_entry)

        editingId = intent.getStringExtra(EXTRA_ID)
        type = intent.getStringExtra(EXTRA_TYPE) ?: VaultEntry.TYPE_PASSWORD

        val inputName = findViewById<TextInputEditText>(R.id.input_name)
        val inputUsername = findViewById<TextInputEditText>(R.id.input_username)
        val inputNotes = findViewById<TextInputEditText>(R.id.input_notes)
        val group = findViewById<RadioGroup>(R.id.input_type)
        val passwordRadio = findViewById<View>(R.id.type_password)
        val passphraseRadio = findViewById<View>(R.id.type_passphrase)

        panelPassword = findViewById(R.id.panel_password)
        panelPassphrase = findViewById(R.id.panel_passphrase)
        inputSecret = findViewById(R.id.input_secret)
        wordsLabel = findViewById(R.id.passphrase_words_label)
        wordsSlider = findViewById(R.id.passphrase_words)
        wordsContainer = findViewById(R.id.passphrase_container)

        val save = findViewById<Button>(R.id.button_save)

        val existing = editingId?.let { id -> VaultStore.entries.firstOrNull { it.id == id } }
        if (existing != null) {
            type = existing.type
            inputName.setText(existing.title)
            inputUsername.setText(existing.username)
            inputNotes.setText(existing.notes)
            if (type == VaultEntry.TYPE_PASSPHRASE) {
                fillWords(existing.secret.split(' ').filter { it.isNotBlank() })
            } else {
                inputSecret.setText(existing.secret)
            }
            save.text = getString(R.string.save)
        }

        group.setOnCheckedChangeListener { _, checkedId ->
            type = if (checkedId == R.id.type_passphrase) {
                VaultEntry.TYPE_PASSPHRASE
            } else {
                VaultEntry.TYPE_PASSWORD
            }
            applyType()
        }
        group.check(if (type == VaultEntry.TYPE_PASSPHRASE) R.id.type_passphrase else R.id.type_password)
        applyType()

        wordsSlider.addOnChangeListener { _, value, _ ->
            wordsLabel.text = getString(R.string.passphrase_words, value.toInt())
        }
        wordsLabel.text = getString(R.string.passphrase_words, wordsSlider.value.toInt())

        findViewById<Button>(R.id.button_generate_password).setOnClickListener {
            inputSecret.setText(PasswordGenerator.password32())
        }
        findViewById<Button>(R.id.button_generate_passphrase).setOnClickListener {
            fillWords(PasswordGenerator.passphrase(wordsSlider.value.toInt()))
        }

        save.setOnClickListener {
            val name = inputName.text?.toString()?.trim().orEmpty()
            val username = inputUsername.text?.toString()?.trim().orEmpty()
            val notes = inputNotes.text?.toString()?.trim().orEmpty()
            if (name.isEmpty()) {
                inputName.error = getString(R.string.name_required)
                return@setOnClickListener
            }
            val secret: String = if (type == VaultEntry.TYPE_PASSPHRASE) {
                collectWords()
            } else {
                inputSecret.text?.toString()?.trim().orEmpty()
            }
            if (type == VaultEntry.TYPE_PASSPHRASE && secret.isEmpty()) {
                Toast.makeText(this, R.string.passphrase_required, Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            if (type == VaultEntry.TYPE_PASSWORD && secret.isEmpty()) {
                Toast.makeText(this, R.string.secret_required, Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            if (existing != null) {
                existing.title = name
                existing.username = username
                existing.notes = notes
                existing.secret = secret
                existing.type = type
                existing.updatedAt = System.currentTimeMillis()
                VaultStore.updateEntry(existing)
            } else {
                VaultStore.addEntry(
                    VaultEntry(
                        title = name,
                        username = username,
                        notes = notes,
                        secret = secret,
                        type = type
                    )
                )
            }
            Toast.makeText(this, R.string.saved, Toast.LENGTH_SHORT).show()
            finish()
        }
    }

    private fun applyType() {
        panelPassword.visibility =
            if (type == VaultEntry.TYPE_PASSWORD) View.VISIBLE else View.GONE
        panelPassphrase.visibility =
            if (type == VaultEntry.TYPE_PASSPHRASE) View.VISIBLE else View.GONE
    }

    private fun fillWords(words: List<String>) {
        wordsContainer.removeAllViews()
        if (words.isEmpty()) {
            // start with a single blank word row
            addWordRow("")
            return
        }
        words.forEach { addWordRow(it) }
        addAddRow()
    }

    private fun addWordRow(word: String) {
        val row = LayoutInflater.from(this)
            .inflate(R.layout.item_edit_word, wordsContainer, false)
        row.findViewById<TextView>(R.id.word_number).text =
            "${wordsContainer.childCount + 1}."
        row.findViewById<TextInputEditText>(R.id.word_input).setText(word)
        row.findViewById<View>(R.id.word_remove).setOnClickListener {
            wordsContainer.removeView(row)
            renumber()
        }
        // insert before the "add word" row
        wordsContainer.addView(row, wordsContainer.childCount - if (hasAddRow()) 1 else 0)
        renumber()
    }

    private fun addAddRow() {
        if (hasAddRow()) return
        val add = LayoutInflater.from(this)
            .inflate(R.layout.item_add_word, wordsContainer, false) as LinearLayout
        add.tag = "add"
        add.setOnClickListener { addWordRow("") }
        wordsContainer.addView(add)
    }

    private fun hasAddRow(): Boolean =
        wordsContainer.childCount > 0 && wordsContainer.getChildAt(wordsContainer.childCount - 1)
            .tag == "add"

    private fun renumber() {
        var n = 1
        for (i in 0 until wordsContainer.childCount) {
            val child = wordsContainer.getChildAt(i)
            if (child.tag == "add") continue
            child.findViewById<TextView>(R.id.word_number).text = "$n."
            n++
        }
    }

    private fun collectWords(): String {
        val words = ArrayList<String>()
        for (i in 0 until wordsContainer.childCount) {
            val child = wordsContainer.getChildAt(i)
            if (child.tag == "add") continue
            val text = child.findViewById<TextInputEditText>(R.id.word_input)
                .text?.toString()?.trim().orEmpty()
            if (text.isNotEmpty()) words.add(text)
        }
        return words.joinToString(" ")
    }

    companion object {
        const val EXTRA_ID = "entry_id"
        const val EXTRA_TYPE = "entry_type"
    }
}
