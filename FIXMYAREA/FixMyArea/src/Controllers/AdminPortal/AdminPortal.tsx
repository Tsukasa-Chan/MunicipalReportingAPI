import "./AdminPortal.module.css"
import Overview from "./sections/Overview"
import Footer from "@/components/reusable_sections/Footer"

export default function AdminPortalPage() {
  return (
    <div className="min-h-screen bg-background flex flex-col">
      <Overview />
      <Footer />
    </div>
  )
}