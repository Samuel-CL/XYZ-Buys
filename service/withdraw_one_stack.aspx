 <%@ Page Language="C#" Debug="true"  Async="true"%>
<%@ Import namespace="System.Web.Configuration" %>
<%@ Import namespace="System" %>
<%@ Import namespace="System.IO" %>
<%@ Import namespace="System.Data.SqlClient" %>
<%@ Import namespace="System.Web.Configuration" %>
<%@ Import namespace="System.Web.Script.Serialization" %>
<%@ Import namespace="System.Security.Cryptography" %>



<script language="c#" runat="server">


    public class ServiceResponse
    {
        public string bank_server;
        public string status;
        public string message;
        public string time;
    }

    //static string path = WebConfigurationManager.AppSettings["root"];
    static string pk = "";
	static string account = "";
	
    //static FileUtils fileUtils = FileUtils(HttpRuntime.AppDomainAppPath + @"\" + path + @"\");

    public void Page_Load(object sender, EventArgs e)
    {	
		Random rnd = new Random();
		int tagrand = rnd.Next(9999);
		string tag = tagrand.ToString();
	
	
	
		string destFile="";
		string fileName ="";
        ServiceResponse serviceResponse = new ServiceResponse();
        serviceResponse.bank_server = WebConfigurationManager.AppSettings["thisServerName"];
        serviceResponse.status = "fail";
        serviceResponse.time = DateTime.UtcNow.ToString("o");


        pk = Request["pk"];
		account = Request["account"];

        if (pk == "" || account == "")
        {
            //Response.Write("Request Error: Private key or Account ID not specified");
            //Response.End();
            serviceResponse.message = "Request Error: Private key or Account ID not specified";
            var json = new JavaScriptSerializer().Serialize(serviceResponse);
            Response.Write(json);
            Response.End();
        }

		string PasswordFolder = WebConfigurationManager.AppSettings["PasswordFolder"];
		
		//check if file exists
		if (System.IO.File.Exists( Server.MapPath("..") + @"\accounts\" + PasswordFolder + @"\" + account + @".txt")){
			
		string text = System.IO.File.ReadAllText( Server.MapPath("..") + @"\accounts\" + PasswordFolder + @"\" + account + @".txt");
		//serviceResponse.account = account;
		
        if ( text != pk )
        {
            serviceResponse.status = "fail";
            serviceResponse.message = "Private key not correct";
            var serialjson = new JavaScriptSerializer().Serialize(serviceResponse);
            Response.Write(serialjson);
            Response.End();
        }
		
	//End of checking passwords
		}else{
		serviceResponse.status = "fail";
            serviceResponse.message = "Account not correct";
            var serialjson = new JavaScriptSerializer().Serialize(serviceResponse);
            Response.Write(serialjson);
            Response.End();
		}
	

        FileUtils fileUtils = new FileUtils(HttpRuntime.AppDomainAppPath + @"\accounts\" + pk + @"\");
        int amount = 0;
        int total = 0;

        try
        {
            amount = Int32.Parse(Request["amount"]);
            total = amount;

        } catch(FormatException ex)
        {
            serviceResponse.message = "Request Error: The amount is not a number";
            var json = new JavaScriptSerializer().Serialize(serviceResponse);
            Response.Write(json);
            Response.End();
        } catch(ArgumentNullException n)
        {
            serviceResponse.message = "Request Error: Amount of CloudCoins not specified";
            var json = new JavaScriptSerializer().Serialize(serviceResponse);
            Response.Write(json);
            Response.End();
        }

        if(amount == 0)
        {
            serviceResponse.message = "Request Error: Amount of CloudCoins not specified";
            var json = new JavaScriptSerializer().Serialize(serviceResponse);
            Response.Write(json);
            Response.End();
        }
        else
        {
  
            Stack response = new Stack();
            Banker bank = new Banker(fileUtils);
            int[] bankTotals = bank.countCoins(fileUtils.BankFolder);
            int[] frackedTotals = bank.countCoins(fileUtils.FrackedFolder);

            int AvailableCoins = ((bankTotals[5] + frackedTotals[5]) * 250) + ((bankTotals[4] + frackedTotals[4]) * 100) + ((bankTotals[3] + frackedTotals[3]) * 25) + ((bankTotals[2] + frackedTotals[2]) * 5) + ((bankTotals[1] + frackedTotals[1]) * 1);
            if (amount > AvailableCoins)
            {
                serviceResponse.message = "Request Error: Amount of CloudCoins not available ";
                var json2 = new JavaScriptSerializer().Serialize(serviceResponse);
                Response.Write(json2);
                Response.End();
            }

            int exp_1 = 0;
            int exp_5 = 0;
            int exp_25 = 0;
            int exp_100 = 0;
            int exp_250 = 0;
            if(amount >= 250 && bankTotals[5] + frackedTotals[5] > 0)
            {
                exp_250 = ((amount / 250) < (bankTotals[5] + frackedTotals[5] )) ? (amount / 250) : (bankTotals[5] + frackedTotals[5]);
                amount -= (exp_250 * 250);
            }
            if(amount >= 100 && bankTotals[4] + frackedTotals[4] > 0)
            {
                exp_100 = ((amount / 100) < (bankTotals[4] + frackedTotals[4]) ) ? (amount / 100) : (bankTotals[4] + frackedTotals[4]);
                amount -= (exp_100 * 100);
            }
            if(amount >= 25 && bankTotals[3] + frackedTotals[3] > 0)
            {
                exp_25 = ((amount / 25) < (bankTotals[3] + frackedTotals[3]) ) ? (amount / 25) : (bankTotals[3] + frackedTotals[3]);
                amount -= (exp_25 * 25);
            }
            if(amount >= 5 && bankTotals[2] + frackedTotals[2] > 0)
            {
                exp_5 = ((amount / 5) < (bankTotals[2] + frackedTotals[2]) ) ? (amount / 5) : (bankTotals[2] + frackedTotals[2]);
                amount -= (exp_5 * 5);
            }
            if(amount >= 1 && bankTotals[1] + frackedTotals[1] > 0)
            {
                exp_1 = (amount  < (bankTotals[1] + frackedTotals[1]) ) ? amount  : (bankTotals[1] + frackedTotals[1]);
                amount -= (exp_1);
            }
            Exporter exporter = new Exporter(fileUtils);
            exporter.writeJSONFile(exp_1, exp_5, exp_25, exp_100, exp_250, tag);
            string path = fileUtils.ExportFolder + Path.DirectorySeparatorChar + total + ".CloudCoins." + tag + ".stack";
            string json = "";
            using (StreamReader sr = File.OpenText(path))
            {

                while (!sr.EndOfStream)
                {
                    json += sr.ReadLine();
                }
            }
            Response.Write(json);
            //Response.Write("{\"cloudcoin\": [{\"nn\":\"1\",\"sn\":\"1\",\"an\":[\"e81b1fe7ae877c1899c39a313d35c88c\", \"c3a6760d9af70f899497269a456808a9\", \"9a1d6d1fbdc640aab102b2680e44c8ce\", \"5b114c8c2c5e811e678f311149276c12\", \"21af83db9fa08381baf54d7e3072cc56\",\"a3e6ffa76dd3544ce86dcf40ed101fba\", \"166fa666bd956cc6eefeb5d5659380fd\", \"6bd70e01c0acf1f235f507af4a686ae1\", \"78daa1698eef67d3fab5558cbac7d0d2\", \"1cf9da8af2d909790081def430eec5fb\",\"ca77671af6e41351ac2ede9cef9708b5\", \"19331d34dfa0b65eb1e392686b32bbd4\", \"0bfde783c96b1d76d07d5feebdc6721e\", \"0b9af86847e5ab492ea9eec7b800fa5c\", \"6e71ea311ee977000503a7bc2cf5ad18\",\"05a1ef8ac8a4634ac6c90210d5f7c981\", \"4e9c863e46d385422878d974de9cd18e\", \"6dcee1fac91d2076c39b4ea83b89b5b9\", \"88f62d78a5305efe33ef3c405427041f\", \"4d5d0ced36da227010abc00a708fe68e\",\"1c41531bd1058655b733f0e02dc72661\", \"e50e960405da7d669606c37745cdf252\", \"a755e06942d65d7460c2498b28bac110\", \"867a0891a19a1d110f83a42bea235745\", \"e22662ec18923719f40ed0cad25a25a9\"],\"ed\":\"11-3000\",\"pown\":\"ppppppppppppppppppppppppp\",\"aoid\":[]}]}");
            Response.End();
			
        }
    }

    </script>