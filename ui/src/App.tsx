import { QueryClientProvider } from "@tanstack/react-query"
import { ChatView } from "./views/ChatView"
import { DatabaseView } from "./views/DatabaseView"
import { NewChatView } from "./views/NewChatView";
import { AuthView } from "./views/AuthView";
import { createBrowserRouter, Outlet, RouterProvider } from "react-router-dom";
import { AppProvider, queryClient, AppContext } from "./AppContext";
import { NavSidebar } from "./views/NavSidebar";
import { SidebarProvider } from "./components/ui/sidebar";
import { Toaster } from "./components/ui/sonner";
import { useContext } from "react";
import { ErrorBoundary } from "./components/ErrorBoundary";
import './App.css'

function Layout() {
  return (
    <SidebarProvider>
      <ErrorBoundary>
        <NavSidebar />
      </ErrorBoundary>
      <ErrorBoundary>
        <Outlet />
      </ErrorBoundary>
    </SidebarProvider>
  );
}

const router = createBrowserRouter([
  {
    element: <Layout />,
    children: [
      {
        path: "/",
        element: <ErrorBoundary><NewChatView /></ErrorBoundary>
      },
      {
        path: "/chat/:chatId",
        element: <ErrorBoundary><ChatView /></ErrorBoundary>
      },
      {
        path: "/database/:databaseId",
        element: <ErrorBoundary><DatabaseView /></ErrorBoundary>
      },
      {
        path: "/explore",
        element: <ErrorBoundary><DatabaseView /></ErrorBoundary>
      },
    ]
  },
]);

function AuthGate() {
  const ctx = useContext(AppContext);
  const isLoggedIn = ctx?.state.currentUser != null;

  if (!isLoggedIn) {
    return <AuthView />;
  }

  return (
    <ErrorBoundary>
      <RouterProvider router={router} />
    </ErrorBoundary>
  );
}

function App() {
  return (
    <ErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <AppProvider>
          <AuthGate />
          <Toaster />
        </AppProvider>
      </QueryClientProvider>
    </ErrorBoundary>
  );
}

export default App
