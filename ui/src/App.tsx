import type { ConversationIdentifier, DatabaseIdentifier, View } from "@/types";
import { useState, useEffect } from 'react'
import { SidebarProvider } from "@/components/ui/sidebar"
import { NavSidebar } from "./views/NavSidebar"
import { ChatView } from "./views/ChatView"
import { DatabaseView } from "./views/DatabaseView"
import './App.css'


function App() {
  const [conversations, setConversations] = useState<ConversationIdentifier[]>([]);
  const [databases, setDatabases] = useState<DatabaseIdentifier[]>([]);
  const [selectedConversation, setSelectedConversation] = useState<string | null>(null);
  const [selectedDatabase, setSelectedDatabase] = useState<string | null>(null);
  const [view, setView] = useState<View>("chat");

  const handleConversationSelect = (conversationId: string) => {
    console.log(`Selected conversation ${conversationId}`);
    setSelectedConversation(conversationId);
    setView("chat");
  };

  const handleDatabaseSelect = (databaseId: string) => {
    console.log(`Selected database ${databaseId}`);
    setSelectedDatabase(databaseId);
    setView("database");
  };

  const fetchConversations = () => {
    fetch("http://localhost:8000/api/conversations")
      .then(res => res.json())
      .then(data => setConversations(data))
      .catch(err => console.error("Fetch conversations failed:", err));
  };

  const fetchDatabases = () => {
    fetch("http://localhost:8000/api/databases")
      .then(res => res.json())
      .then(data => setDatabases(data))
      .catch(err => console.error("Fetch databases failed:", err));
  };

  useEffect(() => {
    fetchConversations();
    fetchDatabases();
  }, []);

  const handleNewConversation = () => {
    console.log("New conversation");
  };

  const handleNewDatabase = () => {
    console.log("New database");
  };

  return (
    <>
      <SidebarProvider>
        <NavSidebar
          onNewConversation={handleNewConversation}
          onSelectConversation={handleConversationSelect}
          onDeleteConversation={() => { }}
          onNewDatabase={handleNewDatabase}
          onSelectDatabase={handleDatabaseSelect}
          onDeleteDatabase={() => { }}
          conversations={conversations}
          databases={databases}
        />
        {view === "chat" && (<ChatView selectedConversationId={selectedConversation} />)}
        {view === "database" && (<DatabaseView selectedDatabaseId={selectedDatabase} />)}
      </SidebarProvider>
    </>
  )
}

export default App
