import { useContext, useState } from "react";
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { AccountSettingsDialog } from "@/components/AccountSettings";
import { AppContext } from "@/AppContext";
import { IconSun, IconMoon, IconUser, IconSettings, IconLogout } from "@tabler/icons-react";
import { SidebarMenuButton } from "@/components/ui/sidebar";

export function AccountDialog() {
    const ctx = useContext(AppContext);
    const user = ctx?.state.currentUser;
    const theme = ctx?.state.theme ?? "light";
    const [settingsOpen, setSettingsOpen] = useState(false);

    return (
        <>
            <AccountSettingsDialog open={settingsOpen} onOpenChange={setSettingsOpen} />

            <DropdownMenu>
                <DropdownMenuTrigger
                    render={
                        <SidebarMenuButton className="active:bg-secondary transition-all duration-50">
                            <IconUser />
                            <span>{user?.username ?? "Account"}</span>
                        </SidebarMenuButton>
                    }
                />

                <DropdownMenuContent side="top" align="start" className="w-52">
                    <DropdownMenuItem onClick={() => ctx?.dispatch({ type: "TOGGLE_THEME" })}>
                        {theme === "dark" ? <IconSun size={14} /> : <IconMoon size={14} />}
                        {theme === "dark" ? "Light Mode" : "Dark Mode"}
                    </DropdownMenuItem>

                    <DropdownMenuItem onClick={() => setSettingsOpen(true)}>
                        <IconSettings size={14} />
                        Account Settings
                    </DropdownMenuItem>

                    <DropdownMenuSeparator />

                    <DropdownMenuItem variant="destructive" onClick={() => ctx?.dispatch({ type: "LOGOUT" })}>
                        <IconLogout size={14} />
                        Sign Out
                    </DropdownMenuItem>
                </DropdownMenuContent>
            </DropdownMenu>
        </>
    );
}
