import { QueryClientProvider } from "@tanstack/react-query"
import { ChatView } from "./views/ChatView"
import { DatabaseView } from "./views/DatabaseView"
import { LandingView } from "./views/LandingView";
import { createBrowserRouter, Outlet, RouterProvider } from "react-router-dom";
import { AppProvider, queryClient } from "./AppContext";
import { NavSidebar } from "./views/NavSidebar";
import { SidebarProvider } from "./components/ui/sidebar";
import './App.css'

function Layout() {
  return (
    <SidebarProvider>
      <NavSidebar />
      <Outlet />
    </SidebarProvider>
  );
}

const router = createBrowserRouter([
  {
    element: <Layout />,
    children: [
      {
        path: "/",
        element: <LandingView
          databases={null}
          selectedDatabase={null}
          onSelectDatabase={() => { }}
        />
      },
      {
        path: "/chat/:chatId",
        element: <ChatView />
      },
      {
        path: "/database/:databaseId",
        element: <DatabaseView />
      },
    ]
  },
]);

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AppProvider>
        <RouterProvider router={router} />
      </AppProvider>
    </QueryClientProvider>
  );
}

export default App
