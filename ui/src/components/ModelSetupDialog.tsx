import { Button } from "@/components/ui/button"
import {
    Dialog,
    DialogClose,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from "@/components/ui/dialog"
import { Field, FieldGroup } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { IconDots } from "@tabler/icons-react"

export function ModelSetupDialog() {
    return (
        <Dialog>
            <form>
                <DialogTrigger>
                    <Button variant="outline"><IconDots /></Button>
                </DialogTrigger>
                <DialogContent className="sm:max-w-2xl">
                    <DialogHeader>
                        <DialogTitle>Model Setup</DialogTitle>
                        <DialogDescription>
                            Tune the system to your needs by setting up the model and databases to use for retrieval.
                        </DialogDescription>
                    </DialogHeader>
                    <FieldGroup>
                        <Field>
                            <Label htmlFor="system">System Prompt</Label>
                            <Input id="system" name="system" defaultValue="You are a helpful assistant for the subject of Functional Programming." />
                        </Field>
                    </FieldGroup>
                    <FieldGroup>
                        <Field>
                            <Label htmlFor="gen-model">Generation Model</Label>
                            <Input id="gen-model" name="gen-model" defaultValue="gpt-4.1" />
                        </Field>
                        <Field>
                            <Label htmlFor="comp-model">Compaction Model</Label>
                            <Input id="comp-model" name="comp-model" defaultValue="gpt-4.1-mini" />
                        </Field>
                        <Field>
                            <Label htmlFor="ver-model">Verification Model</Label>
                            <Input id="ver-model" name="ver-model" defaultValue="gpt-4.1-mini" />
                        </Field>
                        <Field>
                            <Label htmlFor="emb-model">Embedding Model</Label>
                            <Input id="emb-model" name="emb-model" defaultValue="gpt-embedding-small" />
                        </Field>
                    </FieldGroup>
                    <DialogFooter>
                        <DialogClose>
                            <Button variant="outline">Cancel</Button>
                        </DialogClose>
                        <Button type="submit">Save changes</Button>
                    </DialogFooter>
                </DialogContent>
            </form>
        </Dialog>
    )
}
