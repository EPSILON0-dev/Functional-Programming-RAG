import * as React from "react"
import {
  SidebarGroup,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuItem,
  SidebarMenuButton,
  useSidebar,
} from "./ui/sidebar"

import { useContext } from "react";
import { AppContext } from "@/AppContext";
import { ConversationSkeleton } from "./ConversationSkeleton";
import { Skeleton } from "./ui/skeleton";
import { useNavigate } from "react-router-dom";
import { NavChatsDropdown } from "./NavChatsDropdown";

export function NavChats(): React.JSX.Element {
  const { open } = useSidebar();
  const ctx = useContext(AppContext);
  const conversations = ctx?.state.chats ?? null;
  const navigate = useNavigate();

  return (
    <>
      {open && <SidebarGroup>
        <SidebarGroupLabel>
          {conversations ? <div className="select-none">Conversations</div> : <Skeleton className="h-4 w-24" />}
        </SidebarGroupLabel>
        <SidebarMenu>
          {(() => {
            return conversations ? conversations.length > 0 ? conversations.map((conv) => (
              <SidebarMenuItem className="group/item" key={conv.id}>
                <SidebarMenuButton
                  className="active:bg-secondary transition-all duration-50"
                  onClick={() => navigate(`/chat/${conv.id}`)}
                >
                  <span className="whitespace-nowrap truncate">{conv.name}</span>
                  <div className="ml-auto mr-2 max-h-fit">
                    <NavChatsDropdown chatId={conv.id} />
                  </div>
                </SidebarMenuButton>
              </SidebarMenuItem>
            )) : 
            (<>
              <div className="text-sm italic text-muted-foreground px-2 pt-2">No conversations yet</div>
              <div className="text-xs italic text-muted-foreground px-2">Ask a question!</div>
            </>) : 
            (
              <SidebarMenuItem>
                <div className="pointer-events-none">
                  <ConversationSkeleton />
                </div>
              </SidebarMenuItem>
            );
          })()}
        </SidebarMenu>
      </SidebarGroup>
      }
    </>
  )
}
