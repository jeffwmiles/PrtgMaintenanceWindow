<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="_Default" UnobtrusiveValidationMode="None" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>PRTG Maintenance Window Site</title>
    <link href="Style/styles.css" rel="stylesheet" />
    <script src="https://ajax.aspnetcdn.com/ajax/jQuery/jquery-3.3.1.min.js"></script>
    <script src="Scripts/jquery-ui.js"></script>
    <script src="Scripts/jquery-ui-timepicker-addon.js"></script>
    <link href="Scripts/jquery-ui-timepicker-addon.css" type="text/css" rel="stylesheet" />
    <link href="Scripts/jquery-ui.min.css" type="text/css" rel="stylesheet" />
    <script type="text/javascript">
        function pageLoad() {
            $('#txtStartDate').unbind();
            $('#txtStartDate').datetimepicker();
            $('#txtEndDate').unbind();
            $('#txtEndDate').datetimepicker();
        }

        $(function () {
            $('#txtStartDate').datetimepicker({
                timeFormat: "hh:mm tt",
                onSelect: function () {
                    $("#hidden_start").val($(this).datetimepicker("getDate").toISOString());
                }
            });
            $('#txtEndDate').datetimepicker({
                timeFormat: "hh:mm tt",
                onSelect: function () {
                    $("#hidden_end").val($(this).datetimepicker("getDate").toISOString());
                }
            });
        });
    </script>
</head>
<body>
    <form id="form1" runat="server">
        <asp:ScriptManager ID="MainScriptManager" runat="server" />
        <asp:HiddenField ID="hidden_start" runat="server" />
        <asp:HiddenField ID="hidden_end" runat="server" />
        <asp:UpdateProgress ID="updProgress"
            AssociatedUpdatePanelID="UpdatePanel1"
            runat="server">
            <ProgressTemplate>
                <div class="modal">
                    <div class="center">
                        <img alt="progress" src="images/loading3.gif" />
                        Processing...           
                    </div>
                </div>
            </ProgressTemplate>
        </asp:UpdateProgress>
        <div>
            <div class="headerdiv">
                <asp:Label ID="lbl_title" runat="server" CssClass="title" Text="PRTG Maintenance Window Site"></asp:Label>
                <img src="prtg.png" class="logo" />
            </div>
            <div id="pagecontainer">
                <div id="leftside" class="leftcol">
                    <br />
                    <asp:Label ID="lbl_select" runat="server" Text="Select an Action:"></asp:Label>
                    <asp:DropDownList ID="ddl_mainttype" runat="server" AutoPostBack="True" AppendDataBoundItems="false" OnDataBound="ddl_mainttype_DataBound"
                        DataSourceID="XmlDataSource1" DataTextField="Code" DataValueField="Code"
                        OnSelectedIndexChanged="ddl_mainttype_SelectedIndexChanged">
                    </asp:DropDownList><br />
                    <asp:UpdatePanel ID="UpdatePanel1" runat="server">
                        <ContentTemplate>
                            <asp:Panel ID="pnl_client" runat="server" Visible="false" CssClass="pnlstyle">
                                <div class="flex-container">
                                    <div class="flex left">

                                        <asp:Label ID="lbl_maintstart" runat="server" Text="Maintenance start date / time:" CssClass="formlabel"></asp:Label>
                                        <asp:Label ID="lbl_maintend" runat="server" Text="Maintenance end date / time:" CssClass="formlabel"></asp:Label><br />
                                        <asp:Label ID="lbl_includeprod" runat="server" Text="Include Production web servers?" CssClass="formlabel"></asp:Label><br />
                                        <asp:Label ID="lbl_includetest" runat="server" Text="Include Test web servers?" CssClass="formlabel"></asp:Label><br />
                                    </div>

                                    <div class="flex right">
                                        <asp:TextBox ID="txtStartDate" runat="server" TextMode="DateTime"></asp:TextBox><br />
                                        <asp:RequiredFieldValidator ID="val_startdate" runat="server" ErrorMessage="Start Date is required" Display="None" ControlToValidate="txtStartDate" ValidationGroup="valdates"></asp:RequiredFieldValidator>
                                        <asp:TextBox ID="txtEndDate" runat="server" TextMode="DateTime"></asp:TextBox><br />
                                        <asp:RequiredFieldValidator ID="val_enddate" runat="server" ErrorMessage="End Date is required" Display="None" ControlToValidate="txtEndDate" ValidationGroup="valdates"></asp:RequiredFieldValidator>
                                        <%--<asp:CompareValidator ID="val_datecompare" runat="server" ErrorMessage="End Date must be greater than Start Date" Display="None" Type="Date"
                                    ControlToValidate="txtEndDate" ControlToCompare="txtStartDate" Operator="GreaterThan" CultureInvariantValues="true"></asp:CompareValidator>--%>
                                        <asp:CustomValidator ID="val_endcompare" runat="server" ErrorMessage="End Date must be greater than Start Date" Display="None"
                                            ControlToValidate="txtEndDate" ValidateEmptyText="true" OnServerValidate="val_endcompare_ServerValidate" ValidationGroup="valdates"></asp:CustomValidator>
                                        <asp:CheckBox ID="chk_includeprod" runat="server" CssClass="checkleft" /><br />
                                        <asp:CheckBox ID="chk_includetest" runat="server" CssClass="checkleft" /><br />

                                    </div>
                                </div>
                                <asp:ValidationSummary ID="val_summary" runat="server" ValidationGroup="valdates" EnableClientScript="true" DisplayMode="BulletList" ShowSummary="true" ForeColor="Red" Font-Size="12px" />
                                <br />
                                <asp:Button ID="ExecuteCode" runat="server" Text="Add Maintenance Window" ValidationGroup="valdates" CausesValidation="true" Width="200" OnClick="ExecuteCode_Click" />

                            </asp:Panel>
                            <asp:Panel ID="pnl_windowsupdates" runat="server" Visible="false" CssClass="pnlstyle">
                                Test
                            </asp:Panel>
                            <br />
                            <br />
                            <asp:Label ID="lbl_results" runat="server" Text="Results"></asp:Label><br />
                            <asp:TextBox ID="txt_results" TextMode="MultiLine" CssClass="resultsbox" Width="600" Height="200" Font-Size="12px" Font-Names="Courier" runat="server"></asp:TextBox>
                        </ContentTemplate>
                    </asp:UpdatePanel>
                </div>
                <div id="rightsidenotes" class="rightcol">
                    <div id="notes" class="notesdiv">
                        <h1>Notes</h1>
                        <p>This site allows a one-time maintenance window to be added to PRTG, for a pre-defined set of sensors.</p>
                        <p>If a client is selected:</p>
                        <ul>
                            <li>Include Note here</li>
                            <li>Include Note here</li>
                            <li>Include Note here</li>
                        </ul>
                        <p></p>
                        <p>*Tip: add this site to your "Intranet" zone in Internet Explorer to avoid the login prompt.</p>
                    </div>
                </div>
            </div>
        </div>
        <asp:XmlDataSource ID="XmlDataSource1" runat="server" DataFile="~/ActionType.xml"></asp:XmlDataSource>
    </form>
</body>

</html>
