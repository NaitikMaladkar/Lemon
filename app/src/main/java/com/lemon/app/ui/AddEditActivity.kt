package com.lemon.app.ui

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.RadioGroup
import android.widget.Toast
import com.google.android.material.textfield.TextInputEditText
import com.lemon.app.R
import com.lemon.app.data.VaultEntry
import com.lemon.app.data.VaultStore
import com.lemon.app.util.SecureActivity

class AddEditActivity : SecureActivity() {

    private var editId: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_add_edit)

        val title = findViewById<TextInputEditText>(R.id.input_title)
        val username = findViewById<TextInputEditText>(R.id.input_username)
        val secret = findViewById<TextInputEditText>(R.id.input_secret)
        val notes = findViewById<TextInputEditText>(R.id.input_notes)
        val typeGroup = findViewById<RadioGroup>(R.id.input_type)
        val save = findViewById<Button>(R.id.button_save)

        editId = intent.getStringExtra(EXTRA_ID)

        // Prefill when launched from the generator (auto-save or "save to vault").
        title.setText(intent.getStringExtra(EXTRA_TITLE))
        secret.setText(intent.getStringExtra(EXTRA_SECRET))
        username.setText(intent.getStringExtra(EXTRA_USERNAME))
        val type = intent.getStringExtra(EXTRA_TYPE)
        if (type == VaultEntry.TYPE_PASSPHRASE) {
            typeGroup.check(R.id.type_passphrase)
        } else {
            typeGroup.check(R.id.type_password)
        }

        // Auto-save path: save immediately, no form shown.
        if (intent.getBooleanExtra(EXTRA_AUTOSAVE, false)) {
            val entry = VaultEntry(
                title = title.text?.toString()?.trim().orEmpty().ifEmpty { "Generated" },
                username = username.text?.toString()?.trim().orEmpty(),
                secret = secret.text?.toString().orEmpty(),
                type = if (typeGroup.checkedRadioButtonId == R.id.type_passphrase)
                    VaultEntry.TYPE_PASSPHRASE else VaultEntry.TYPE_PASSWORD
            )
            VaultStore.addEntry(entry)
            Toast.makeText(this, R.string.gen_saved_toast, Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        // Load existing entry for editing.
        val existing = editId?.let { id -> VaultStore.entries.firstOrNull { it.id == id } }
        if (existing != null) {
            title.setText(existing.title)
            username.setText(existing.username)
            secret.setText(existing.secret)
            notes.setText(existing.notes)
            if (existing.type == VaultEntry.TYPE_PASSPHRASE) {
                typeGroup.check(R.id.type_passphrase)
            }
        }

        save.setOnClickListener {
            val t = title.text?.toString()?.trim().orEmpty()
            if (t.isEmpty()) {
                Toast.makeText(this, R.string.title_required, Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            val entryType = if (typeGroup.checkedRadioButtonId == R.id.type_passphrase)
                VaultEntry.TYPE_PASSPHRASE else VaultEntry.TYPE_PASSWORD

            if (existing != null) {
                existing.title = t
                existing.username = username.text?.toString()?.trim().orEmpty()
                existing.secret = secret.text?.toString().orEmpty()
                existing.notes = notes.text?.toString()?.trim().orEmpty()
                existing.type = entryType
                existing.updatedAt = System.currentTimeMillis()
                VaultStore.updateEntry(existing)
            } else {
                VaultStore.addEntry(
                    VaultEntry(
                        title = t,
                        username = username.text?.toString()?.trim().orEmpty(),
                        secret = secret.text?.toString().orEmpty(),
                        notes = notes.text?.toString()?.trim().orEmpty(),
                        type = entryType
                    )
                )
            }
            Toast.makeText(this, R.string.saved, Toast.LENGTH_SHORT).show()
            finish()
        }
    }

    companion object {
        const val EXTRA_ID = "extra_id"
        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_SECRET = "extra_secret"
        const val EXTRA_USERNAME = "extra_username"
        const val EXTRA_TYPE = "extra_type"
        const val EXTRA_AUTOSAVE = "extra_autosave"

        fun copyToClipboard(context: Context, text: String) {
            val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            cm.setPrimaryClip(ClipData.newPlainText("lemon", text))
        }
    }
}
