import "./SinglePostTemplate.module.css"
import Header from "@/components/reusable_sections/Header"
import Article from "./sections/Article"
import Footer from "@/components/reusable_sections/Footer"

export default function SinglePostTemplatePage() {

  return (
    <div>
      <Header />
      <Article />
      <Footer />
    </div>
  )
}