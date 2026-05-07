"use client"

import { Button } from "@/components/ui/button"
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { IconChevronDown, IconCylinder } from "@tabler/icons-react"
import { AppContext } from "@/AppContext"
import { useContext } from "react"

export function DatabaseDropdown(): React.JSX.Element {
    const ctx = useContext(AppContext);
    const databases = ctx?.state.databases ?? null;
    const selectedDatabase = ctx?.state.selectedDatabase ?? null;

    return (
        <div className={`${databases === null ? "pointer-events-none" : ""}`}>
            <DropdownMenu >
                <DropdownMenuTrigger render={
                    <Button variant="outline">
                        <IconCylinder />
                        {databases === null ? "Loading ..." :
                            (selectedDatabase === null ? "Select Database" :
                                databases !== null && databases?.find((x) => x.id === selectedDatabase?.id)?.name)}
                        <IconChevronDown />
                    </Button>
                } />
                <DropdownMenuContent className="w-60" align="start">
                    {databases?.map((db) => (
                        <div key={db.name}>
                            <DropdownMenuItem
                                onClick={() => { ctx?.dispatch({ type: "SELECT_DATABASE", payload: db }) }}
                            >
                                <IconCylinder />{db.name}
                            </DropdownMenuItem>
                        </div>
                    ))}
                </DropdownMenuContent>
            </DropdownMenu>
        </div>
    )
}
