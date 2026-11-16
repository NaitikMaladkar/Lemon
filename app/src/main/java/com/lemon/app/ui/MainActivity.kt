package com.lemon.app.ui

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.widget.Toolbar
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.floatingactionbutton.FloatingActionButton
import com.lemon.app.R
import com.lemon.app.data.TotpEntry
import com.lemon.app.data.VaultStore
import com.lemon.app.util.SecureActivity

/**
 * Home screen: live TOTP codes. Top bar: lock, password manager, settings.
 */
class MainActivity : SecureActivity() {

    private lateinit var list: RecyclerView
    private lateinit var empty: TextView
    private lateinit var adapter: TotpAdapter

    private val ticker = object : Runnable {
        override fun run() {
            adapter.refresh()
            list.postDelayed(this, 1000)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val toolbar = findViewById<Toolbar>(R.id.toolbar)
        setSupportActionBar(toolbar)

        list = findViewById(R.id.totp_list)
        empty = findViewById(R.id.empty_view)
        list.layoutManager = LinearLayoutManager(this)

        adapter = TotpAdapter(
            items = VaultStore.totps,
            onCopy = { copyCode(it) },
            onMore = { showMore(it) }
        )
        list.adapter = adapter

        findViewById<FloatingActionButton>(R.id.fab_add_totp).setOnClickListener {
            showAddChooser()
        }
    }

    override fun onResume() {
        super.onResume()
        refresh()
        list.postDelayed(ticker, 1000)
    }

    override fun onPause() {
        super.onPause()
        list.removeCallbacks(ticker)
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.menu_main, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_password_manager -> {
                startActivity(Intent(this, PasswordManagerActivity::class.java))
                true
            }
            R.id.action_settings -> {
                startActivity(Intent(this, SettingsActivity::class.java))
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    private fun refresh() {
        adapter.notifyDataSetChanged()
        empty.visibility = if (VaultStore.totps.isEmpty()) TextView.VISIBLE else TextView.GONE
    }

    private fun showAddChooser() {
        val options = arrayOf(
            getString(R.string.totp_scan),
            getString(R.string.totp_manual)
        )
        AlertDialog.Builder(this)
            .setTitle(R.string.totp_add)
            .setItems(options) { _, which ->
                when (which) {
                    0 -> startActivity(Intent(this, ScannerActivity::class.java))
                    1 -> startActivity(Intent(this, AddTotpActivity::class.java))
                }
            }
            .show()
    }

    private fun showMore(entry: TotpEntry) {
        val options = arrayOf(getString(R.string.edit), getString(R.string.delete))
        AlertDialog.Builder(this)
            .setTitle(entry.label)
            .setItems(options) { _, which ->
                when (which) {
                    0 -> startActivity(
                        Intent(this, AddTotpActivity::class.java)
                            .putExtra(AddTotpActivity.EXTRA_ID, entry.id)
                    )
                    1 -> confirmDelete(entry)
                }
            }
            .show()
    }

    private fun confirmDelete(entry: TotpEntry) {
        AlertDialog.Builder(this)
            .setTitle(R.string.delete_confirm)
            .setPositiveButton(R.string.delete) { _, _ ->
                VaultStore.deleteTotp(entry.id)
                refresh()
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun copyCode(entry: TotpEntry) {
        val code = Totp.code(
            entry.secret,
            period = entry.period,
            digits = entry.digits,
            algorithm = entry.algorithm
        )
        val cm = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        cm.setPrimaryClip(ClipData.newPlainText("totp", code))
        Toast.makeText(this, R.string.copied, Toast.LENGTH_SHORT).show()
    }
}
