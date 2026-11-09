import "./SearchTemplate.module.css"
import Header from "@/components/reusable_sections/Header"
import SearchResults from "./sections/SearchResults"
import Footer from "@/components/reusable_sections/Footer"

export default function SearchTemplatePage() {

  return (
    <div>
      <Header />
      <SearchResults />
      <Footer />
    </div>
  )
}
