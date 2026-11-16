package com.lemon.app.ui.passwords

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.PopupMenu
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.lemon.app.R
import com.lemon.app.data.VaultEntry

class EntryAdapter(
    private val onEdit: (VaultEntry) -> Unit,
    private val onDelete: (VaultEntry) -> Unit,
    private val onCopySecret: (VaultEntry) -> Unit,
    private val onCopyUsername: (VaultEntry) -> Unit
) : RecyclerView.Adapter<EntryAdapter.VH>() {

    private val items = ArrayList<VaultEntry>()
    private val revealed = HashSet<String>()

    fun submit(list: List<VaultEntry>) {
        items.clear()
        items.addAll(list)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_entry, parent, false)
        return VH(view)
    }

    override fun getItemCount(): Int = items.size

    override fun onBindViewHolder(holder: VH, position: Int) {
        val entry = items[position]
        holder.title.text = entry.title
        holder.username.text = entry.username
        holder.username.visibility = if (entry.username.isEmpty()) View.GONE else View.VISIBLE

        val isRevealed = revealed.contains(entry.id)
        holder.secret.text = if (isRevealed) entry.secret else "•".repeat(entry.secret.length.coerceAtMost(18).coerceAtLeast(4))
        holder.reveal.setImageResource(
            if (isRevealed) R.drawable.ic_visibility_off else R.drawable.ic_visibility
        )
        holder.reveal.contentDescription = holder.itemView.context.getString(
            if (isRevealed) R.string.hide else R.string.reveal
        )
        holder.reveal.setOnClickListener {
            if (revealed.contains(entry.id)) revealed.remove(entry.id) else revealed.add(entry.id)
            if (holder.adapterPosition != RecyclerView.NO_POSITION) {
                notifyItemChanged(holder.adapterPosition)
            }
        }
        holder.copy.setOnClickListener { onCopySecret(entry) }

        holder.more.setOnClickListener { v ->
            val menu = PopupMenu(v.context, v)
            menu.inflate(R.menu.menu_entry)
            menu.menu.findItem(R.id.action_copy_username).isVisible = entry.username.isNotEmpty()
            menu.menu.findItem(R.id.action_reveal).title =
                v.context.getString(if (isRevealed) R.string.hide else R.string.reveal)
            menu.setOnMenuItemClickListener { mi ->
                when (mi.itemId) {
                    R.id.action_copy_secret -> onCopySecret(entry)
                    R.id.action_copy_username -> onCopyUsername(entry)
                    R.id.action_reveal -> {
                        if (revealed.contains(entry.id)) revealed.remove(entry.id) else revealed.add(entry.id)
                        if (holder.adapterPosition != RecyclerView.NO_POSITION) {
                            notifyItemChanged(holder.adapterPosition)
                        }
                    }
                    R.id.action_edit -> onEdit(entry)
                    R.id.action_delete -> onDelete(entry)
                }
                true
            }
            menu.show()
        }

        holder.title.setOnClickListener { onEdit(entry) }
    }

    class VH(view: View) : RecyclerView.ViewHolder(view) {
        val title: TextView = view.findViewById(R.id.entry_title)
        val username: TextView = view.findViewById(R.id.entry_username)
        val secret: TextView = view.findViewById(R.id.entry_secret)
        val reveal: ImageButton = view.findViewById(R.id.entry_reveal)
        val copy: ImageButton = view.findViewById(R.id.entry_copy)
        val more: ImageButton = view.findViewById(R.id.entry_more)
    }
}
