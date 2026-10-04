package ru.hundrik.portfolio;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet(urlPatterns = {"/api/hello", "/healthz", "/readyz"})
public class AppServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("text/plain;charset=UTF-8");
        response.setHeader("Cache-Control", "no-store");
        if (!request.getServletPath().equals("/api/hello")) {
            response.getWriter().print("ok");
            return;
        }
        try {
            response.getWriter().print(Greeting.message(request.getParameter("name")));
        } catch (IllegalArgumentException e) {
            response.setStatus(400);
            response.getWriter().print(e.getMessage());
        }
    }
}
