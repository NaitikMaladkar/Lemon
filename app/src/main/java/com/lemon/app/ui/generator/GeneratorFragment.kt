package com.lemon.app.ui.generator

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.CheckBox
import android.widget.CompoundButton
import android.widget.ImageButton
import android.widget.Spinner
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.google.android.material.chip.Chip
import com.google.android.material.slider.Slider
import com.google.android.material.tabs.TabLayout
import com.google.android.material.textfield.TextInputEditText
import com.lemon.app.R
import com.lemon.app.data.VaultEntry
import com.lemon.app.data.VaultStore
import com.lemon.app.gen.PasswordGenerator
import com.lemon.app.ui.AddEditActivity

class GeneratorFragment : Fragment(R.layout.fragment_generator) {

    private var password = ""
    private var passphrase = ""
    private var type = VaultEntry.TYPE_PASSWORD

    private lateinit var autosave: CompoundButton
    private lateinit var saveTitle: TextInputEditText

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val tabs = view.findViewById<TabLayout>(R.id.gen_tabs)
        val panelPassword = view.findViewById<View>(R.id.panel_password)
        val panelPassphrase = view.findViewById<View>(R.id.panel_passphrase)

        val passwordOutput = view.findViewById<TextView>(R.id.password_output)
        val passphraseOutput = view.findViewById<TextView>(R.id.passphrase_output)
        val lengthSlider = view.findViewById<Slider>(R.id.password_length)
        val lengthLabel = view.findViewById<TextView>(R.id.password_length_label)
        val wordsSlider = view.findViewById<Slider>(R.id.passphrase_words)
        val wordsLabel = view.findViewById<TextView>(R.id.passphrase_words_label)
        val separator = view.findViewById<Spinner>(R.id.passphrase_separator)

        val chipUpper = view.findViewById<Chip>(R.id.chip_upper)
        val chipLower = view.findViewById<Chip>(R.id.chip_lower)
        val chipDigits = view.findViewById<Chip>(R.id.chip_digits)
        val chipSymbols = view.findViewById<Chip>(R.id.chip_symbols)
        val capitalize = view.findViewById<CheckBox>(R.id.passphrase_capitalize)
        val addNumber = view.findViewById<CheckBox>(R.id.passphrase_add_number)

        saveTitle = view.findViewById(R.id.save_title)
        autosave = view.findViewById(R.id.save_autosave)
        val saveButton = view.findViewById<Button>(R.id.save_button)
        val copyButton = view.findViewById<Button>(R.id.save_copy)

        val separators = listOf("-", ".", " ", "_", "+")
        separator.adapter = ArrayAdapter(
            requireContext(),
            android.R.layout.simple_spinner_dropdown_item,
            separators
        )

        tabs.addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
            override fun onTabSelected(tab: TabLayout.Tab) {
                type = if (tab.position == 0) VaultEntry.TYPE_PASSWORD else VaultEntry.TYPE_PASSPHRASE
                panelPassword.visibility = if (tab.position == 0) View.VISIBLE else View.GONE
                panelPassphrase.visibility = if (tab.position == 0) View.GONE else View.VISIBLE
            }

            override fun onTabUnselected(tab: TabLayout.Tab) {}
            override fun onTabReselected(tab: TabLayout.Tab) {}
        })

        fun maybeAutosave(secret: String) {
            if (!autosave.isChecked) return
            val title = saveTitle.text?.toString()?.trim().orEmpty()
            if (title.isEmpty()) return
            // Update the entry with the same title instead of piling up duplicates
            // every time a new secret is generated.
            val existing = VaultStore.entries.firstOrNull {
                it.title.equals(title, ignoreCase = true) && it.type == type
            }
            if (existing != null) {
                existing.secret = secret
                existing.updatedAt = System.currentTimeMillis()
                VaultStore.updateEntry(existing)
            } else {
                VaultStore.addEntry(
                    VaultEntry(
                        title = title,
                        secret = secret,
                        type = type
                    )
                )
            }
            Toast.makeText(requireContext(), R.string.gen_saved_toast, Toast.LENGTH_SHORT).show()
        }

        fun regeneratePassword() {
            if (!chipUpper.isChecked && !chipLower.isChecked && !chipDigits.isChecked && !chipSymbols.isChecked) {
                Toast.makeText(requireContext(), R.string.gen_choose_at_least_one, Toast.LENGTH_SHORT).show()
                return
            }
            password = PasswordGenerator.password(
                length = lengthSlider.value.toInt(),
                upper = chipUpper.isChecked,
                lower = chipLower.isChecked,
                digits = chipDigits.isChecked,
                symbols = chipSymbols.isChecked
            )
            passwordOutput.text = password
            maybeAutosave(password)
        }

        fun regeneratePassphrase() {
            passphrase = PasswordGenerator.passphrase(
                words = wordsSlider.value.toInt(),
                capitalize = capitalize.isChecked,
                addNumber = addNumber.isChecked,
                separator = separators[separator.selectedItemPosition]
            )
            passphraseOutput.text = passphrase
            maybeAutosave(passphrase)
        }

        lengthSlider.addOnChangeListener { _, value, _ ->
            lengthLabel.text = getString(R.string.gen_length, value.toInt())
        }
        wordsSlider.addOnChangeListener { _, value, _ ->
            wordsLabel.text = getString(R.string.gen_words, value.toInt())
        }

        view.findViewById<ImageButton>(R.id.password_regen).setOnClickListener { regeneratePassword() }
        view.findViewById<ImageButton>(R.id.passphrase_regen).setOnClickListener { regeneratePassphrase() }

        saveButton.setOnClickListener {
            val secret = if (type == VaultEntry.TYPE_PASSWORD) password else passphrase
            if (secret.isEmpty()) {
                Toast.makeText(requireContext(), R.string.gen_choose_at_least_one, Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            val i = Intent(requireContext(), AddEditActivity::class.java)
            i.putExtra(AddEditActivity.EXTRA_TITLE, saveTitle.text?.toString()?.trim().orEmpty())
            i.putExtra(AddEditActivity.EXTRA_SECRET, secret)
            i.putExtra(AddEditActivity.EXTRA_TYPE, type)
            startActivity(i)
        }

        copyButton.setOnClickListener {
            val secret = if (type == VaultEntry.TYPE_PASSWORD) password else passphrase
            if (secret.isEmpty()) return@setOnClickListener
            AddEditActivity.copyToClipboard(requireContext(), secret)
            Toast.makeText(requireContext(), R.string.copied, Toast.LENGTH_SHORT).show()
        }

        lengthLabel.text = getString(R.string.gen_length, lengthSlider.value.toInt())
        wordsLabel.text = getString(R.string.gen_words, wordsSlider.value.toInt())
        regeneratePassword()
        regeneratePassphrase()
    }
}
