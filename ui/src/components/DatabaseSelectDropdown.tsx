"use client"

import { Button } from "@/components/ui/button"
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { IconChevronDown, IconCylinder } from "@tabler/icons-react"

interface DatabaseSelectionDropdownInterface {
    databases: { label: string }[]
}

export function DatabaseSelectionDropdown({ databases }: DatabaseSelectionDropdownInterface): React.JSX.Element {
    return (
        <DropdownMenu>
            <DropdownMenuTrigger render={
                <Button variant="outline">
                    <IconCylinder />
                    {databases[0].label}
                    <IconChevronDown />
                </Button>
            } />
            <DropdownMenuContent className="w-60" align="start">
                {databases.map((db) => (
                    <div key={db.label}>
                        <DropdownMenuItem><IconCylinder />{db.label}</DropdownMenuItem>
                    </div>
                ))}
            </DropdownMenuContent>
        </DropdownMenu>
    )
}
