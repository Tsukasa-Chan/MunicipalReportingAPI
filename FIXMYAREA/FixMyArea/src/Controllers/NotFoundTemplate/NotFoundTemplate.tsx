import "./NotFoundTemplate.module.css"
import Header from "@/components/reusable_sections/Header"
import NotFound from "./sections/NotFound"
import Footer from "@/components/reusable_sections/Footer"

export default function NotFoundTemplatePage() {

  return (
    <div>
      <Header />
      <NotFound />
      <Footer />
    </div>
  )
}
