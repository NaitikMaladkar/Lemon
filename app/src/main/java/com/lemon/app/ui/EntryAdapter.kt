package com.lemon.app.ui

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.lemon.app.R
import com.lemon.app.data.VaultEntry

/**
 * Lists saved passwords and passphrases.
 *  - password row: name, username, secret; tap copies
 *  - passphrase row: name, username, tap expands to the numbered words
 */
class EntryAdapter(
    private val items: MutableList<VaultEntry>,
    private val onCopy: (VaultEntry) -> Unit,
    private val onEdit: (VaultEntry) -> Unit,
    private val onDelete: (VaultEntry) -> Unit
) : RecyclerView.Adapter<RecyclerView.ViewHolder>() {

    private val expanded = HashSet<String>()

    class PasswordVH(view: View) : RecyclerView.ViewHolder(view) {
        val name: TextView = view.findViewById(R.id.entry_name)
        val username: TextView = view.findViewById(R.id.entry_username)
        val secret: TextView = view.findViewById(R.id.entry_secret)
        val copy: ImageButton = view.findViewById(R.id.btn_copy)
        val edit: ImageButton = view.findViewById(R.id.btn_edit)
        val delete: ImageButton = view.findViewById(R.id.btn_delete)
    }

    class PassphraseVH(view: View) : RecyclerView.ViewHolder(view) {
        val name: TextView = view.findViewById(R.id.entry_name)
        val username: TextView = view.findViewById(R.id.entry_username)
        val hint: TextView = view.findViewById(R.id.entry_hint)
        val words: LinearLayout = view.findViewById(R.id.words_container)
        val copy: ImageButton = view.findViewById(R.id.btn_copy)
        val edit: ImageButton = view.findViewById(R.id.btn_edit)
        val delete: ImageButton = view.findViewById(R.id.btn_delete)
    }

    override fun getItemViewType(position: Int): Int =
        if (items[position].type == VaultEntry.TYPE_PASSPHRASE) TYPE_PASSPHRASE else TYPE_PASSWORD

    override fun getItemCount(): Int = items.size

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        val inflater = LayoutInflater.from(parent.context)
        return if (viewType == TYPE_PASSPHRASE) {
            PassphraseVH(inflater.inflate(R.layout.item_passphrase, parent, false))
        } else {
            PasswordVH(inflater.inflate(R.layout.item_password, parent, false))
        }
    }

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        val entry = items[position]
        when (holder) {
            is PasswordVH -> bindPassword(holder, entry)
            is PassphraseVH -> bindPassphrase(holder, entry)
        }
    }

    private fun bindPassword(holder: PasswordVH, entry: VaultEntry) {
        holder.name.text = entry.title
        holder.username.text = entry.username
        holder.username.visibility = if (entry.username.isEmpty()) View.GONE else View.VISIBLE
        holder.secret.text = entry.secret
        holder.itemView.setOnClickListener { onCopy(entry) }
        holder.copy.setOnClickListener { onCopy(entry) }
        holder.edit.setOnClickListener { onEdit(entry) }
        holder.delete.setOnClickListener { onDelete(entry) }
    }

    private fun bindPassphrase(holder: PassphraseVH, entry: VaultEntry) {
        holder.name.text = entry.title
        holder.username.text = entry.username
        holder.username.visibility = if (entry.username.isEmpty()) View.GONE else View.VISIBLE
        val isOpen = expanded.contains(entry.id)
        holder.words.removeAllViews()
        if (isOpen) {
            holder.hint.setText(R.string.tap_to_collapse)
            holder.words.visibility = View.VISIBLE
            val words = entry.secret.split(' ').filter { it.isNotBlank() }
            val inflater = LayoutInflater.from(holder.itemView.context)
            words.forEachIndexed { i, word ->
                val row = inflater.inflate(R.layout.item_word, holder.words, false)
                row.findViewById<TextView>(R.id.word_number).text = "${i + 1}."
                row.findViewById<TextView>(R.id.word_text).text = word
                holder.words.addView(row)
            }
        } else {
            holder.hint.setText(R.string.tap_to_expand)
            holder.words.visibility = View.GONE
        }
        holder.itemView.setOnClickListener {
            if (expanded.contains(entry.id)) expanded.remove(entry.id) else expanded.add(entry.id)
            notifyItemChanged(holder.adapterPosition)
        }
        holder.copy.setOnClickListener { onCopy(entry) }
        holder.edit.setOnClickListener { onEdit(entry) }
        holder.delete.setOnClickListener { onDelete(entry) }
    }

    fun submit(newItems: List<VaultEntry>) {
        items.clear()
        items.addAll(newItems)
        expanded.clear()
        notifyDataSetChanged()
    }

    fun refresh() {
        expanded.clear()
        notifyDataSetChanged()
    }

    companion object {
        private const val TYPE_PASSWORD = 0
        private const val TYPE_PASSPHRASE = 1
    }
}
