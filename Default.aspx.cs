using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Management.Automation;
using System.Text;
using System.Collections;
using System.Net.Mail;
using System.Xml.Linq;
using System.Xml;

public partial class _Default : System.Web.UI.Page
{
    public bool isingroup = false;
    // Populate the username from logged on user for use with email notification
    public string username = System.Web.HttpContext.Current.Request.LogonUserIdentity.Name.Split('\\')[1];
    protected void Page_Load(object sender, EventArgs e)
    {

        if (!IsPostBack)
        {
            // Build string array based on logged on user
            string[] arr =
                System.Web.HttpContext.Current.Request.
                LogonUserIdentity.Name.Split('\\');
            username = arr[1];
            ArrayList al = new ArrayList();
            // For the array list, run GetGroups function for AD groups
            al = GetGroups();
            foreach (string s in al)
            {
                // if user is in groupname, populate the variable for use in modifying the dropdownlist selection items. 
                if (s == "domain\\groupname")
                {
                    // Do something
                    isingroup = true;
                }
            }
        }

    }
    public ArrayList GetGroups()
    {
        ArrayList groups = new ArrayList();
        foreach (System.Security.Principal.IdentityReference group in
        System.Web.HttpContext.Current.Request.LogonUserIdentity.Groups)
        {
            groups.Add(group.Translate(typeof
            (System.Security.Principal.NTAccount)).ToString());
        }
        return groups;
    }

    public string[] EmailAddressLookup(string typecode)
    {
        // using the xml file, find the email address element for the selected code from the drop down list
        XmlDocument doc = XmlDataSource1.GetXmlDocument();
        XmlElement root = doc.DocumentElement;
        XmlNodeList nodes = root.SelectNodes("/types/type[@Code='" + typecode + "']/emailaddress");
        string emailaddress = nodes[0].ChildNodes[0].Value;
        string[] emaillist = emailaddress.Split(',');
        return emaillist;
    }

    protected void ddl_mainttype_DataBound(object sender, EventArgs e)
    {
        // If not in secTechSupport AD group, remove WindowsUpdates from the drop down list.
        if (!isingroup)
        {
            ddl_mainttype.Items.Remove(ddl_mainttype.Items.FindByValue("WindowsUpdates"));
        }
    }
    protected void ddl_mainttype_SelectedIndexChanged(object sender, EventArgs e)
    {
        // Modify the panel displayed based on selection of drop down list
        string selectedtype = ddl_mainttype.SelectedItem.Text;
        if (selectedtype != "WindowsUpdates")
        {
            pnl_client.Visible = true;
            pnl_windowsupdates.Visible = false;
        }
        else
        {
            pnl_client.Visible = false;
            pnl_windowsupdates.Visible = true;
        }
    }
    protected void ExecuteCode_Click(object sender, EventArgs e)
    {
        if (IsValid == false)
            return;

        bool includeprodserver = false;
        bool includetestserver = false;
        DateTime startdate = Convert.ToDateTime(txtStartDate.Text);
        DateTime enddate = Convert.ToDateTime(txtEndDate.Text);
        string typecode = ddl_mainttype.SelectedItem.Text;
        if (typecode != "WindowsUpdates")
        {
            includeprodserver = chk_includeprod.Checked;
            includetestserver = chk_includetest.Checked;
        }

        // Clean the Result TextBox
        txt_results.Text = string.Empty;

        // Initialize PowerShell engine
        var shell = PowerShell.Create();

        StringBuilder sb = new StringBuilder("");
        // If running in debug, make sure we're using the testscript.
        if (HttpContext.Current.Request.IsLocal)
        {
            sb.Append("C:\\temp\\testscript.ps1" + " ");
        }
        else
        {
            sb.Append("E:\\inetpub\\PRTGMaintenance\\PRTGMaintenanceWindow_" + typecode + ".ps1" + " ");
            //StringBuilder sb = new StringBuilder("E:\\inetpub\\PRTGMaintenance\\testscript.ps1" + " ");
        }

        sb.Append("-MaintStartTime " + "'" + startdate + "'" + " -MaintEndTime " + "'" + enddate + "' ");
        sb.Append(includeprodserver ? " -IncludeProdWebServers" : "");
        sb.Append(includetestserver ? " -IncludeTestWebServers" : "");
        string scriptcommand = sb.ToString();

        // Add the script to the PowerShell object
        shell.Commands.AddScript(scriptcommand);

        // Execute the script
        var results = shell.Invoke();

        // display results, with BaseObject converted to string
        // Note : use |out-string for console-like output
        if (results.Count > 0)
        {
            // We use a string builder ton create our result text
            var builder = new StringBuilder();

            foreach (var psObject in results)
            {
                // Convert the Base Object to a string and append it to the string builder.
                // Add \r\n for line breaks
                builder.Append(psObject.BaseObject.ToString() + "\r\n");
            }

            // Encode the string in HTML (prevent security issue with 'dangerous' caracters like < >
            txt_results.Text = Server.HtmlEncode(builder.ToString());
        }

        // EMAIL SENDING CODE  //

        MailMessage message = new MailMessage();
        message.From = new MailAddress("fromemail@domain.com");
        string[] emaillist = EmailAddressLookup(typecode);
        // If not running in Visual Studio, grab the actual email addresses from xml
        if (!HttpContext.Current.Request.IsLocal)
        {
            foreach (string email in emaillist)
            {
                message.To.Add(new MailAddress(email));
            }
            # always add a TO for IT Team
			message.To.Add(new MailAddress("itteam@domain.com"));
        }
        else
        {
            # Send to test account
			message.To.Add(new MailAddress("myname@domain.com"));
        }
        message.Subject = typecode + " - PRTG One-Time Maintenance window added.";

        StringBuilder sbemail = new StringBuilder("");
        sbemail.Append("A PRTG one-time maintenance window has been added for: " + typecode);
        sbemail.Append(Environment.NewLine).Append(Environment.NewLine);
        sbemail.Append("    Maintenance Start: " + startdate).Append(Environment.NewLine);
        sbemail.Append("    Maintenance End: " + enddate).Append(Environment.NewLine);
        sbemail.Append("    Include Prod Webservers: " + includeprodserver.ToString()).Append(Environment.NewLine);
        sbemail.Append("    Include Test Webservers: " + includetestserver.ToString()).Append(Environment.NewLine);
        sbemail.Append("    Actioned by: " + username).Append(Environment.NewLine);

        sbemail.Append(Environment.NewLine);
        message.Body = sbemail.ToString();

        SmtpClient client = new SmtpClient();
        client.Send(message); # Uses web.config settings for email server

        if (!HttpContext.Current.Request.IsLocal)
        {
            txt_results.Text += "Notification email sent to " + string.Join(",", emaillist) + ".";
        }
        else
        {
            txt_results.Text += "Notification email sent to myname@domain.com.";
        }
    }

    protected void val_endcompare_ServerValidate(object source, ServerValidateEventArgs args)
    {
        DateTime startdate = Convert.ToDateTime(txtStartDate.Text);
        DateTime enddate = Convert.ToDateTime(txtEndDate.Text);

        if (enddate > startdate)
            args.IsValid = true;
        else
            args.IsValid = false;
    }


}