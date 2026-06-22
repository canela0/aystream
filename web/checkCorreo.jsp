<%@page contentType="application/json" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%
  String correo = request.getParameter("correo");
  boolean existe = false;
  if (correo != null && !correo.trim().isEmpty()) {
    Connection con = null;
    try {
      Class.forName("com.mysql.cj.jdbc.Driver");
      con = com.devbiz.util.DB.getConnection();
      PreparedStatement st = con.prepareStatement("SELECT id FROM usuarios WHERE correo=?");
      st.setString(1, correo.trim());
      ResultSet rs = st.executeQuery();
      existe = rs.next();
      rs.close(); st.close();
    } catch(Exception e) {}
    finally { if(con!=null) try{con.close();}catch(Exception e){} }
  }
  out.print("{\"existe\":" + existe + "}");
%>
