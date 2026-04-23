import { AlertCircleIcon } from "lucide-react"

import {
  Alert,
  AlertDescription,
  AlertTitle,
} from "@/components/ui/alert"

export function ConnectionErrorAlert() {
  return (
    <Alert variant="destructive" className="max-w-md">
      <AlertCircleIcon />
      <AlertTitle>Connection Error</AlertTitle>
      <AlertDescription>
        There was a problem connecting to the server. Please check your internet
        connection and try again.
      </AlertDescription>
    </Alert>
  )
}
