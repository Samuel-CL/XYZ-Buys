﻿<%@ Page Language="C#" Debug="true"  Async="true"%>
<%@ Import namespace="System.Web.Configuration" %>
<%@ Import namespace="System" %>
<%@ Import Namespace="System.IO" %>
<%@ Import namespace="System.Data.SqlClient" %>
<%@ Import namespace="System.Web.Configuration" %>
<%@ Import namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="System.Net.Mail" %>
<%@ Import Namespace="System.Net.Mime" %>



<script language="c#" runat="server">



    static string path = WebConfigurationManager.AppSettings["root"];
    static FileUtils fileUtils = FileUtils.GetInstance(HttpRuntime.AppDomainAppPath.ToString() + @"\" + path + @"\");



    public class ServiceResponse
    {
        public string server;
        public string status;

        public string message;
        public string time;
    }//End Service Response class

    public void Page_Load(object sender, EventArgs e)
    {

        ServiceResponse response = new ServiceResponse();
        response.server = WebConfigurationManager.AppSettings["thisServerName"];
        response.time = DateTime.Now.ToString("yyyy-MM-dd h:mm:tt");

        string receive = CheckParameter("receive");
        string id = CheckParameter("id");

        string file = AppDomain.CurrentDomain.BaseDirectory + WebConfigurationManager.AppSettings["root"] + @"\Checks\" + "CloudCoins." + id + ".stack";
        if(id == "")
        {
            response.status = "fail";
            response.message="Please supply a check ID.";
            var json = new JavaScriptSerializer().Serialize(response);
            Response.Write(json);
            Response.End();
        }
        else if(!File.Exists(file))
        {
            response.status = "fail";
            response.message="The check you requested was not found on the server. It may have been cashed, canceled or you have provided an id that is incorrect.";
            var json = new JavaScriptSerializer().Serialize(response);
            Response.Write(json);
            Response.End();
        }


        string check_path = fileUtils.RootPath + Path.DirectorySeparatorChar + "Checks" + Path.DirectorySeparatorChar +  "CloudCoins." + id + ".stack";

        BankXMLUtils bxu = new BankXMLUtils();

        int checkRow = 0;
        checkRow = bxu.FindCheckRow(id);
        if (checkRow > 0)
        {
            bxu.MarkCheckPaid(checkRow);
            bxu.DeleteFromPending(checkRow);
        }
        switch (receive)
        {
            case "json":

                string json = "";
                using (StreamReader sr = File.OpenText(check_path))
                {

                    while (!sr.EndOfStream)
                    {
                        json += sr.ReadLine();
                    }
                }
                Response.Write(json);
                Response.End();
                break;
            case "sms":
                response.status = "not yet implemented";
                response.message="receiving checks by sms not yet implemented";
                var sjson = new JavaScriptSerializer().Serialize(response);
                Response.Write(sjson);
                Response.End();
                break;
            case "email":
                string emailto = CheckParameter("email");
                string from = CheckParameter("from");

                if (WebConfigurationManager.AppSettings["smtpServer"] != "" && WebConfigurationManager.AppSettings["smtpLogin"] != "" && WebConfigurationManager.AppSettings["smtpPassword"] != "")
                {
                    MailMessage mail = new MailMessage(from, emailto);
                    SmtpClient client = new SmtpClient();
                    client.Port = 25;
                    client.DeliveryMethod = SmtpDeliveryMethod.Network;
                    //client.UseDefaultCredentials = false;
                    client.Host = WebConfigurationManager.AppSettings["smtpServer"];
                    client.Credentials = new System.Net.NetworkCredential(WebConfigurationManager.AppSettings["smtpLogin"], WebConfigurationManager.AppSettings["smtpPassword"]);
                    mail.Subject = "CloudCoins Stack sent from Check";
                    ContentType type = new ContentType();
                    type.MediaType = MediaTypeNames.Text.Plain;
                    type.Name = "CloudCoins." + id + ".stack";
                    mail.Attachments.Add(new Attachment(check_path, type));
                    client.Send(mail);
                }

                //SmtpClient cli = new SmtpClient();
                //MailAddress MAfrom = new MailAddress(from);
                //MailAddress to = new MailAddress(emailto);
                //MailMessage message = new MailMessage(MAfrom, to);

                //message.Subject = "CloudCoins Stack sent from Check";
                //ContentType type = new ContentType();
                //type.MediaType = MediaTypeNames.Text.Plain;
                //type.Name = "CloudCoins." + id + ".stack";
                //message.Attachments.Add(new Attachment(check_path, type));

                //cli.SendAsync(message, "CloudBank Check");

                response.status = "success";
                response.message="CloudCoin stack file sent via email and has been deleted from this server.";
                var ejson = new JavaScriptSerializer().Serialize(response);
                Response.Write(ejson);
                Response.End();
                break;
            default:
            case "download":
                Response.Clear();
                Response.AppendHeader("Content-Disposition", "attachment; filename=CloudCoins." + id+".stack" );
                Response.TransmitFile(check_path);
                Response.End();
                break;
        }




    }

    string CheckParameter(string param)
    {
        if (Request[param] != null)
            return Request[param];
        else
            return "";
    }



    </script>