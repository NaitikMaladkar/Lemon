package com.lemon.app.ui

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.widget.Toolbar
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.floatingactionbutton.FloatingActionButton
import com.google.android.material.tabs.TabLayout
import com.lemon.app.R
import com.lemon.app.data.VaultEntry
import com.lemon.app.data.VaultStore
import com.lemon.app.util.SecureActivity

/**
 * Popup-style password manager: Passwords and Passphrases tabs.
 */
class PasswordManagerActivity : SecureActivity() {

    private lateinit var passwordsAdapter: EntryAdapter
    private lateinit var passphrasesAdapter: EntryAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_password_manager)

        val toolbar = findViewById<Toolbar>(R.id.toolbar)
        setSupportActionBar(toolbar)
        toolbar.setNavigationOnClickListener { finish() }

        passwordsAdapter = EntryAdapter(
            items = mutableListOf(),
            onCopy = { copy(it) },
            onEdit = { edit(it) },
            onDelete = { confirmDelete(it) }
        )
        passphrasesAdapter = EntryAdapter(
            items = mutableListOf(),
            onCopy = { copy(it) },
            onEdit = { edit(it) },
            onDelete = { confirmDelete(it) }
        )

        val listPasswords = findViewById<RecyclerView>(R.id.list_passwords)
        val listPassphrases = findViewById<RecyclerView>(R.id.list_passphrases)
        listPasswords.layoutManager = LinearLayoutManager(this)
        listPassphrases.layoutManager = LinearLayoutManager(this)
        listPasswords.adapter = passwordsAdapter
        listPassphrases.adapter = passphrasesAdapter

        val tabs = findViewById<TabLayout>(R.id.tabs)
        tabs.addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
            override fun onTabSelected(tab: TabLayout.Tab) = showTab(tab.position)
            override fun onTabUnselected(tab: TabLayout.Tab) {}
            override fun onTabReselected(tab: TabLayout.Tab) {}
        })
        showTab(0)

        findViewById<FloatingActionButton>(R.id.fab_add).setOnClickListener {
            val type = if (tabs.selectedTabPosition == 1) {
                VaultEntry.TYPE_PASSPHRASE
            } else {
                VaultEntry.TYPE_PASSWORD
            }
            startActivity(
                Intent(this, AddEntryActivity::class.java)
                    .putExtra(AddEntryActivity.EXTRA_TYPE, type)
            )
        }
    }

    override fun onResume() {
        super.onResume()
        rebuildLists()
    }

    private fun rebuildLists() {
        passwordsAdapter.submit(
            VaultStore.entries.filter { it.type == VaultEntry.TYPE_PASSWORD }
        )
        passphrasesAdapter.submit(
            VaultStore.entries.filter { it.type == VaultEntry.TYPE_PASSPHRASE }
        )
        showTab(findViewById<TabLayout>(R.id.tabs).selectedTabPosition)
    }

    private fun showTab(position: Int) {
        val listPasswords = findViewById<RecyclerView>(R.id.list_passwords)
        val listPassphrases = findViewById<RecyclerView>(R.id.list_passphrases)
        val emptyPasswords = findViewById<TextView>(R.id.empty_passwords)
        val emptyPassphrases = findViewById<TextView>(R.id.empty_passphrases)

        if (position == 0) {
            listPasswords.visibility = View.VISIBLE
            listPassphrases.visibility = View.GONE
            emptyPasswords.visibility =
                if (passwordsAdapter.itemCount == 0) View.VISIBLE else View.GONE
            emptyPassphrases.visibility = View.GONE
        } else {
            listPasswords.visibility = View.GONE
            listPassphrases.visibility = View.VISIBLE
            emptyPasswords.visibility = View.GONE
            emptyPassphrases.visibility =
                if (passphrasesAdapter.itemCount == 0) View.VISIBLE else View.GONE
        }
    }

    private fun copy(entry: VaultEntry) {
        val cm = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        cm.setPrimaryClip(ClipData.newPlainText(entry.title, entry.secret))
        Toast.makeText(this, R.string.copied, Toast.LENGTH_SHORT).show()
    }

    private fun edit(entry: VaultEntry) {
        startActivity(
            Intent(this, AddEntryActivity::class.java)
                .putExtra(AddEntryActivity.EXTRA_ID, entry.id)
        )
    }

    private fun confirmDelete(entry: VaultEntry) {
        AlertDialog.Builder(this)
            .setTitle(R.string.delete_confirm)
            .setPositiveButton(R.string.delete) { _, _ ->
                VaultStore.deleteEntry(entry.id)
                rebuildLists()
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }
}
