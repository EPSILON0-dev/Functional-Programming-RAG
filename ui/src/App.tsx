import type { NamedIdentifier, View } from "@/types";
import { useState, useEffect } from 'react'
import { SidebarProvider } from "@/components/ui/sidebar"
import { NavSidebar } from "./views/NavSidebar"
import { ChatView } from "./views/ChatView"
import { DatabaseView } from "./views/DatabaseView"
import './App.css'
import { LandingView } from "./views/LandingView";


function App() {
  const [conversations, setConversations] = useState<NamedIdentifier[] | null>(null);
  const [databases, setDatabases] = useState<NamedIdentifier[] | null>(null);
  const [viewedConversation, setViewedConversation] = useState<NamedIdentifier | null>(null);
  const [viewedDatabase, setViewedDatabase] = useState<NamedIdentifier | null>(null);
  const [selectedDatabase, setSelectedDatabase] = useState<NamedIdentifier | null>(null);
  const [selectedPreset, setSelectedPreset] = useState<NamedIdentifier | null>(null);
  const [view, setView] = useState<View>("landing");

  const handleConversationViewSelect = (conversation: NamedIdentifier) => {
    console.log(`Viewing conversation ${conversation}`);
    setViewedConversation(conversation);
    setView("chat");
  };

  const handleDatabaseViewSelect = (database: NamedIdentifier) => {
    console.log(`Viewing database ${database}`);
    setViewedDatabase(database);
    setView("database");
  };

  const handleConversationNew = () => {
    console.log("New conversation");
    setView("landing");
  }

  const handleDatabaseSelect = (database: NamedIdentifier) => {
    console.log(`Selected database ${database}`);
    setSelectedDatabase(database);
  }

  const fetchConversations = () => {
    fetch("http://localhost:8000/api/conversations")
      .then(res => res.json())
      .then(data => setConversations(data))
      .catch(err => {
        console.error("Fetch conversations failed:", err);
        setConversations(null);
      });
  };

  const fetchDatabases = () => {
    fetch("http://localhost:8000/api/databases")
      .then(res => res.json())
      .then(data => setDatabases(data))
      .catch(err => {
        console.error("Fetch databases failed:", err);
        setDatabases(null);
      });
  };

  useEffect(() => {
    fetchConversations();
    fetchDatabases();
  }, []);

  const handleDatabaseNew = () => {
    console.log("New database");
  };

  return (
    <>
      <SidebarProvider>
        <NavSidebar
          onNewConversation={handleConversationNew}
          onSelectConversation={handleConversationViewSelect}
          onDeleteConversation={() => { }}
          onNewDatabase={handleDatabaseNew}
          onSelectDatabase={handleDatabaseViewSelect}
          onDeleteDatabase={() => { }}
          conversations={conversations}
          databases={databases}
        />
        {view === "landing" && (
          <LandingView
            databases={databases}
            selectedDatabase={selectedDatabase}
            onSelectDatabase={handleDatabaseSelect}
          />
        )}
        {view === "chat" && (
          <ChatView
            viewedConversation={viewedConversation}
          />
        )}
        {view === "database" && (
          <DatabaseView
            viewedDatabase={viewedDatabase}
          />
        )}
      </SidebarProvider>
    </>
  )
}

export default App
