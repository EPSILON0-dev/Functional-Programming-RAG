import {
    Sidebar,
    SidebarContent,
    SidebarFooter,
    useSidebar,
} from "@/components/ui/sidebar"

import { NavDatabases } from "@/components/NavDatabases"
import { NavHeader } from "@/components/NavHeader"
import { NavConversations } from "@/components/NavConversations"

interface NavSidebarInterface {
    onNewConversation: () => void;
    onSelectConversation: (conversationId: string) => void;
    onDeleteConversation: (conversationId: string) => void;
    conversations: { id: string, label: string }[];
    onNewDatabase: () => void;
    onSelectDatabase: (databaseId: string) => void;
    onDeleteDatabase: (databaseId: string) => void;
    databases: { id: string, label: string }[];
};

export function NavSidebar(props: NavSidebarInterface): React.JSX.Element {
    const { open } = useSidebar()
    return (
        <Sidebar collapsible="icon">
            <NavHeader
                open={open}
                onNewConversation={props.onNewConversation}
                onNewDatabase={props.onNewDatabase}
            />
            <SidebarContent className={`${open ? "" : "pointer-events-none"}`}>
                <NavDatabases
                    open={open}
                    databases={props.databases}
                    onDatabaseSelect={props.onSelectDatabase}
                />
                <NavConversations
                    conversations={props.conversations}
                    onConversationSelect={props.onSelectConversation}
                />
            </SidebarContent>
            <SidebarFooter>
            </SidebarFooter>
        </Sidebar >
    )
}
