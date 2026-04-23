import * as React from "react"
import {
    SidebarGroup,
    SidebarGroupLabel,
    SidebarMenu,
    SidebarMenuItem,
    SidebarMenuButton,
    useSidebar,
} from "./ui/sidebar"

import { IconDots } from "@tabler/icons-react"
import { useContext } from "react";
import { AppContext } from "@/AppContext";
import { ConversationSkeleton } from "./ConversationSkeleton";
import { Skeleton } from "./ui/skeleton";
import { useNavigate } from "react-router-dom";

export function NavChats(): React.JSX.Element {
    const { open } = useSidebar();
    const ctx = useContext(AppContext);
    const conversations = ctx?.state.chats ?? null;
    const navigate = useNavigate();

    return (
        <>
            {open && <SidebarGroup>
                <SidebarGroupLabel>
                    {conversations ? "Conversations" : <Skeleton className="h-4 w-24" />}
                </SidebarGroupLabel>
                <SidebarMenu>
                    {(() => {
                        return conversations ? conversations.map((conv) => (
                            <SidebarMenuItem className="group/item" key={conv.id}>
                                <SidebarMenuButton
                                    className="active:bg-gray-200 transition-all duration-50"
                                    onClick={() => navigate(`/chat/${conv.id}`)}
                                >
                                    <span className="whitespace-nowrap truncate">{conv.label}</span>
                                    <div
                                        className="ml-auto mr-2 max-h-fit"
                                        onClick={(e) => { e.stopPropagation(); console.log(`Conversation ${conv.label} options clicked`); }}
                                    >
                                        <IconDots className="opacity-40 max-w-0 group-hover/item:max-w-full hover:opacity-100 transition-all duration-100" />
                                    </div>
                                </SidebarMenuButton>
                            </SidebarMenuItem>
                        )) : (
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
