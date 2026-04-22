import { Send } from "lucide-react"

export function ChatInput() {
  return (
    <div className="border rounded-xl flex items-center px-3 py-2 bg-background">
      
      
      <textarea
        placeholder="Type your message..."
        className="flex-1 resize-none bg-transparent outline-none text-sm"
        rows={1}
      />

      <button className="ml-2 p-2 rounded-lg hover:bg-muted transition">
        <Send className="w-4 h-4" />
      </button>

    </div>
  )
}
