import {
    Sidebar,
    SidebarContent,
    SidebarFooter,
    SidebarMenu,
    SidebarMenuItem,
    useSidebar,
} from "@/components/ui/sidebar"

import { NavDatabases } from "@/components/NavDatabases"
import { NavHeader } from "@/components/NavHeader"
import { NavChats } from "@/components/NavChats"
import { AccountDialog } from "@/components/AccountDialog"

export function NavSidebar(): React.JSX.Element {
    const { open } = useSidebar()
    return (
        <Sidebar collapsible="icon">
            <NavHeader />
            <SidebarContent className={`${open ? "" : "pointer-events-none"}`}>
                <NavDatabases />
                <NavChats />
            </SidebarContent>
            <SidebarFooter>
                <SidebarMenu>
                    <SidebarMenuItem>
                        <AccountDialog />
                    </SidebarMenuItem>
                </SidebarMenu>
            </SidebarFooter>
        </Sidebar >
    )
}
