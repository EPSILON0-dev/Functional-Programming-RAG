"use client"

import { Button } from "@/components/ui/button"
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { IconAdjustmentsHorizontal, IconChevronDown } from "@tabler/icons-react"

interface Props {
    presets: { name: string }[]
}

export function PresetSelectionDropdown({ presets }: Props): React.JSX.Element {
    return (
        <DropdownMenu>
            <DropdownMenuTrigger render={
                <Button variant="outline">
                    <IconAdjustmentsHorizontal />
                    {presets[0].name}
                    <IconChevronDown />
                </Button>
            } />
            <DropdownMenuContent className="w-60" align="start">
                {presets.map((preset) => (
                    <div key={preset.name}>
                        <DropdownMenuItem><IconAdjustmentsHorizontal />{preset.name}</DropdownMenuItem>
                    </div>
                ))}
            </DropdownMenuContent>
        </DropdownMenu>
    )
}
