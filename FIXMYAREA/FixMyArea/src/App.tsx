import { BrowserRouter, Routes, Route } from "react-router-dom"
import AdminPortalPage from "@/Controllers/AdminPortal/AdminPortal"
import SearchTemplatePage from "@/Controllers/SearchTemplate/SearchTemplate"
import SinglePostTemplatePage from "@/Controllers/SinglePostTemplate/SinglePostTemplate"
import NotFoundTemplatePage from "@/Controllers/NotFoundTemplate/NotFoundTemplate"

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<AdminPortalPage />} />
        <Route path="/search" element={<SearchTemplatePage />} />
        <Route path="/post/:slug" element={<SinglePostTemplatePage />} />
        <Route path="*" element={<NotFoundTemplatePage />} />
      </Routes>
    </BrowserRouter>
  )
}
