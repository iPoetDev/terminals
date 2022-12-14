# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

# Load the C# code that is used by this module
Add-Type -TypeDefinition @'
using Microsoft.Win32.SafeHandles;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.ConstrainedExecution;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Text;

namespace PSIntegrity
{
    internal class NativeHelpers
    {
        [StructLayout(LayoutKind.Sequential)]
        public struct ACE_HEADER
        {
            public byte AceType;
            public AceFlags AceFlags;
            public UInt16 AceSize;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct ACL_REVISION_INFORMATION
        {
            public UInt32 AclRevision;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct ACL_SIZE_INFORMATION
        {
            public UInt32 AceCount;
            public UInt32 AclBytesInUse;
            public UInt32 AclBytesFree;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct LUID
        {
            public UInt32 LowPart;
            public Int32 HighPart;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct LUID_AND_ATTRIBUTES
        {
            public LUID Luid;
            public UInt32 Attributes;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct SYSTEM_MANDATORY_LABEL_ACE
        {
            public ACE_HEADER Header;
            public MandatoryLabelMask Mask;
            public UInt32 SidStart;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct TOKEN_PRIVILEGES
        {
            public UInt32 PrivilegeCount;
            [MarshalAs(UnmanagedType.ByValArray, SizeConst = 1)]
            public LUID_AND_ATTRIBUTES[] Privileges;
        }

        public enum ACL_INFORMATION_CLASS : uint
        {
            AclRevisionInformation = 1,
            AclSizeInformation,
        }

        [Flags]
        public enum SECURITY_INFORMATION : uint
        {
            OWNER_SECURITY_INFORMATION = 0x00000001,
            GROUP_SECURITY_INFORMATION = 0x00000002,
            DACL_SECURITY_INFORMATION = 0x00000004,
            SACL_SECURITY_INFORMATION = 0x00000008,
            UNPROTECTED_SACL_SECURITY_INFORMATION = 0x10000000,
            UNPROTECTED_DACL_SECURITY_INFORMATION = 0x20000000,
            PROTECTED_SACL_SECURITY_INFORMATION = 0x40000000,
            PROTECTED_DACL_SECURITY_INFORMATION = 0x80000000,
            LABEL_SECURITY_INFORMATION = 0x00000010,
        }
    }

    internal class NativeMethods
    {
        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern bool AddMandatoryAce(
            SafeMemoryBuffer pAcl,
            UInt32 dwAceRevision,
            [MarshalAs(UnmanagedType.U1)] AceFlags AceFlags,
            [MarshalAs(UnmanagedType.U4)] MandatoryLabelMask MandatoryPolicy,
            SafeMemoryBuffer pLabelSid);

        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern bool AdjustTokenPrivileges(
            SafeNativeHandle TokenHandle,
            [MarshalAs(UnmanagedType.Bool)] bool DisableAllPrivileges,
            SafeMemoryBuffer NewState,
            UInt32 BufferLength,
            SafeMemoryBuffer PreviousState,
            out UInt32 ReturnLength);

        [DllImport("kernel32.dll")]
        public static extern bool CloseHandle(
            IntPtr hObject);

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern SafeFileHandle CreateFileW(
                [MarshalAs(UnmanagedType.LPWStr)] string lpFileName,
                [MarshalAs(UnmanagedType.U4)] FileSystemRights dwDesiredAccess,
                [MarshalAs(UnmanagedType.U4)] FileShare dwShareMode,
                IntPtr lpSecurityAttributes,
                [MarshalAs(UnmanagedType.U4)] FileMode dwCreationDisposition,
                UInt32 dwFlagsAndAttributes,
                IntPtr hTemplateFile);

        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern bool DeleteAce(
            IntPtr pAcl,
            UInt32 dwAceIndex);

        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern bool GetAce(
            IntPtr pAcl,
            UInt32 dwAceIndex,
            out IntPtr pAce);

        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern bool GetAclInformation(
            IntPtr pAcl,
            SafeMemoryBuffer pAclInformation,
            UInt32 nAclInformationLength,
            NativeHelpers.ACL_INFORMATION_CLASS dwAclInformationClass);

        [DllImport("kernel32")]
        public static extern SafeWaitHandle GetCurrentProcess();

        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern UInt32 GetSecurityInfo(
            SafeHandle handle,
            [MarshalAs(UnmanagedType.U4)] ResourceType ObjectType,
            UInt32 SecurityInfo,
            out IntPtr ppsidOwner,
            out IntPtr ppsidGroup,
            out IntPtr ppDacl,
            out IntPtr ppSacl,
            out SafeSecurityDescriptorBuffer ppSecurityDescriptor);

        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern bool InitializeAcl(
            SafeMemoryBuffer pAcl,
            UInt32 nAclLength,
            UInt32 dwAclRevision);

        [DllImport("kernel32.dll")]
        public static extern IntPtr LocalFree(
            IntPtr hMem);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool LookupPrivilegeName(
            [MarshalAs(UnmanagedType.LPWStr)] string lpSystemName,
            ref NativeHelpers.LUID lpLuid,
            StringBuilder lpName,
            ref UInt32 cchName);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool LookupPrivilegeValue(
            [MarshalAs(UnmanagedType.LPWStr)] string lpSystemName,
            [MarshalAs(UnmanagedType.LPWStr)] string lpName,
            out NativeHelpers.LUID lpLuid);

        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern bool OpenProcessToken(
            SafeHandle ProcessHandle,
            [MarshalAs(UnmanagedType.U4)] TokenAccessLevels DesiredAccess,
            out SafeNativeHandle TokenHandle);

        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern UInt32 SetSecurityInfo(
            SafeHandle handle,
            [MarshalAs(UnmanagedType.U4)] ResourceType ObjectType,
            UInt32 SecurityInfo,
            IntPtr psidOwner,
            IntPtr psidGroup,
            IntPtr pDacl,
            IntPtr pSacl);
    }

    internal class PrivilegeEnabler : IDisposable
    {
        private SafeHandle process;
        private Dictionary<string, bool> previousState;

        public PrivilegeEnabler(params string[] privileges)
        {
            if (privileges.Length > 0)
            {
                process = NativeMethods.GetCurrentProcess();
                Dictionary<string, bool> newState = new Dictionary<string, bool>();
                for (int i = 0; i < privileges.Length; i++)
                    newState.Add(privileges[i], true);
                try
                {
                    previousState = SetTokenPrivileges(process, newState);
                }
                catch (Win32Exception e)
                {
                    throw new Win32Exception(e.NativeErrorCode, String.Format("Failed to enable privilege(s) {0}", String.Join(", ", privileges)));
                }
            }
        }

        public static Dictionary<string, bool> SetTokenPrivileges(SafeHandle token, IDictionary<string, bool> state)
        {
            NativeHelpers.LUID_AND_ATTRIBUTES[] privilegeAttr = new NativeHelpers.LUID_AND_ATTRIBUTES[state.Count];
            int i = 0;

            foreach (KeyValuePair<string, bool> entry in state)
            {
                NativeHelpers.LUID luid;
                if (!NativeMethods.LookupPrivilegeValue(null, entry.Key, out luid))
                    throw new Win32Exception(String.Format("LookupPrivilegeValue({0}) failed", entry.Key));

                privilegeAttr[i].Luid = luid;
                privilegeAttr[i].Attributes = (UInt32)(entry.Value ? 0x00000002 : 0x00000000);
                i++;
            }

            return AdjustTokenPrivileges(token, privilegeAttr);
        }

        private static Dictionary<string, bool> AdjustTokenPrivileges(SafeHandle token, NativeHelpers.LUID_AND_ATTRIBUTES[] newState)
        {
            int tokenPrivilegesSize = Marshal.SizeOf(typeof(NativeHelpers.TOKEN_PRIVILEGES));
            int luidAttrSize = 0;
            if (newState.Length > 1)
                luidAttrSize = Marshal.SizeOf(typeof(NativeHelpers.LUID_AND_ATTRIBUTES)) * (newState.Length - 1);
            int totalSize = tokenPrivilegesSize + luidAttrSize;
            byte[] newStateBytes = new byte[totalSize];

            // get the first entry that includes the struct details
            NativeHelpers.TOKEN_PRIVILEGES tokenPrivileges = new NativeHelpers.TOKEN_PRIVILEGES()
            {
                PrivilegeCount = (UInt32)newState.Length,
                Privileges = new NativeHelpers.LUID_AND_ATTRIBUTES[1],
            };
            if (newState.Length > 0)
                tokenPrivileges.Privileges[0] = newState[0];
            int offset = StructureToBytes(tokenPrivileges, newStateBytes, 0);

            // copy the remaining LUID_AND_ATTRIBUTES (if any)
            for (int i = 1; i < newState.Length; i++)
                offset += StructureToBytes(newState[i], newStateBytes, offset);

            // finally create the pointer to the byte array we just created
            using (SafeMemoryBuffer newStatePtr = new SafeMemoryBuffer(newStateBytes.Length))
            {
                Marshal.Copy(newStateBytes, 0, newStatePtr.DangerousGetHandle(), newStateBytes.Length);

                SafeNativeHandle hToken;
                if (!NativeMethods.OpenProcessToken(token, TokenAccessLevels.Query | TokenAccessLevels.AdjustPrivileges, out hToken))
                    throw new Win32Exception("OpenProcessToken() failed with Query and AdjustPrivileges");

                NativeHelpers.LUID_AND_ATTRIBUTES[] oldStatePrivileges;
                using (hToken)
                {
                    UInt32 returnLength;
                    if (!NativeMethods.AdjustTokenPrivileges(hToken, false, newStatePtr, 0, new SafeMemoryBuffer(0), out returnLength))
                    {
                        int errCode = Marshal.GetLastWin32Error();
                        if (errCode != 122) // ERROR_INSUFFICIENT_BUFFER
                            throw new Win32Exception(errCode, "AdjustTokenPrivileges() failed to get old state size");
                    }

                    using (SafeMemoryBuffer oldStatePtr = new SafeMemoryBuffer((int)returnLength))
                    {
                        bool res = NativeMethods.AdjustTokenPrivileges(hToken, false, newStatePtr, returnLength, oldStatePtr, out returnLength);
                        int errCode = Marshal.GetLastWin32Error();

                        if (!res || !(errCode == 0 || errCode == 0x00000514))  // ERROR_NOT_ALL_ASSIGNED
                            throw new Win32Exception(errCode, "AdjustTokenPrivileges() failed");

                        // Marshal the oldStatePtr to the struct
                        NativeHelpers.TOKEN_PRIVILEGES oldState = (NativeHelpers.TOKEN_PRIVILEGES)Marshal.PtrToStructure(
                            oldStatePtr.DangerousGetHandle(), typeof(NativeHelpers.TOKEN_PRIVILEGES));
                        oldStatePrivileges = new NativeHelpers.LUID_AND_ATTRIBUTES[oldState.PrivilegeCount];
                        PtrToStructureArray(oldStatePrivileges, IntPtr.Add(oldStatePtr.DangerousGetHandle(), Marshal.SizeOf(oldState.PrivilegeCount)));
                    }
                }
                return oldStatePrivileges.ToDictionary(p => GetPrivilegeName(p.Luid),
                    p => ((p.Attributes & (UInt32)0x00000002) != 0));
            }
        }

        private static string GetPrivilegeName(NativeHelpers.LUID luid)
        {
            UInt32 nameLen = 0;
            NativeMethods.LookupPrivilegeName(null, ref luid, null, ref nameLen);

            StringBuilder name = new StringBuilder((int)(nameLen + 1));
            if (!NativeMethods.LookupPrivilegeName(null, ref luid, name, ref nameLen))
                throw new Win32Exception("LookupPrivilegeName() failed");

            return name.ToString();
        }

        private static void PtrToStructureArray<T>(T[] array, IntPtr ptr)
        {
            IntPtr ptrOffset = ptr;
            for (int i = 0; i < array.Length; i++, ptrOffset = IntPtr.Add(ptrOffset, Marshal.SizeOf(typeof(T))))
                array[i] = (T)Marshal.PtrToStructure(ptrOffset, typeof(T));
        }

        private static int StructureToBytes<T>(T structure, byte[] array, int offset)
        {
            int size = Marshal.SizeOf(structure);
            using (SafeMemoryBuffer structPtr = new SafeMemoryBuffer(size))
            {
                Marshal.StructureToPtr(structure, structPtr.DangerousGetHandle(), false);
                Marshal.Copy(structPtr.DangerousGetHandle(), array, offset, size);
            }

            return size;
        }

        public void Dispose()
        {
            // disables any privileges that were enabled by this class
            if (previousState != null)
                SetTokenPrivileges(process, previousState);
            GC.SuppressFinalize(this);
        }
        ~PrivilegeEnabler() { this.Dispose(); }
    }

    internal class SafeMemoryBuffer : SafeHandleZeroOrMinusOneIsInvalid
    {
        public SafeMemoryBuffer() : base(true) { }
        public SafeMemoryBuffer(int cb) : base(true)
        {
            base.SetHandle(Marshal.AllocHGlobal(cb));
        }
        public SafeMemoryBuffer(IntPtr ptr) : base(true)
        {
            base.SetHandle(ptr);
        }

        [ReliabilityContract(Consistency.WillNotCorruptState, Cer.MayFail)]
        protected override bool ReleaseHandle()
        {
            Marshal.FreeHGlobal(handle);
            return true;
        }
    }

    internal class SafeNativeHandle : SafeHandleZeroOrMinusOneIsInvalid
    {
        public SafeNativeHandle() : base(true) { }

        [ReliabilityContract(Consistency.WillNotCorruptState, Cer.MayFail)]
        protected override bool ReleaseHandle()
        {
            return NativeMethods.CloseHandle(handle);
        }
    }

    internal class SafeSecurityDescriptorBuffer : SafeHandleZeroOrMinusOneIsInvalid
    {
        public SafeSecurityDescriptorBuffer() : base(true) { }

        [ReliabilityContract(Consistency.WillNotCorruptState, Cer.MayFail)]
        protected override bool ReleaseHandle()
        {
            return NativeMethods.LocalFree(handle) == IntPtr.Zero;
        }
    }

    public class Win32Exception : System.ComponentModel.Win32Exception
    {
        private string _exception_msg;
        public Win32Exception(string message) : this(Marshal.GetLastWin32Error(), message) { }
        public Win32Exception(int errorCode, string message) : base(errorCode)
        {
            _exception_msg = String.Format("{0} - {1} (Win32 Error Code {2}: 0x{3})",
                message, base.Message, errorCode, errorCode.ToString("X8"));
        }
        public override string Message { get { return _exception_msg; } }
        public static explicit operator Win32Exception(string message) { return new Win32Exception(message); }
    }

    public abstract class BaseObjectLabel
    {
        private const UInt32 LABEL_SECURITY_INFORMATION = 0x00000010;

        private ResourceType resourceType;
        private bool isDirty = false;
        private AceFlags aceFlags;
        private MandatoryLabel label;
        private MandatoryLabelMask accessMask;
        private UInt32 revision = 2;  // ACL_REVISION

        public AceFlags AceFlags
        {
            get { return aceFlags; }
            set
            {
                if (aceFlags != value)
                {
                    if (value.HasFlag(AceFlags.InheritOnly))
                        throw new ArgumentException("Cannot set the InheritOnly ACE Flag on a mandatory label ACE");

                    aceFlags = value;
                    isDirty = true;
                }
            }
        }

        public MandatoryLabel Label
        {
            get { return label; }
            set
            {
                if (value == MandatoryLabel.Unknown)
                    throw new ArgumentException("Cannot set Unknown as a label type");

                if (AceFlags.HasFlag(AceFlags.Inherited))
                    throw new InvalidOperationException("Cannot set different Label when the label is inherited");

                if (label != value)
                {
                    label = value;
                    Sid = ConvertLabelToSid(value);
                    if (value == MandatoryLabel.None)
                    {
                        aceFlags = AceFlags.None;
                        accessMask = MandatoryLabelMask.None;
                    }

                    isDirty = true;
                }
            }
        }

        public MandatoryLabelMask AccessMask
        {
            get { return accessMask; }
            set
            {
                if (AceFlags.HasFlag(AceFlags.Inherited))
                    throw new InvalidOperationException("Cannot set different AccessMask when the label is inherited");

                if (accessMask != value)
                {
                    accessMask = value;
                    isDirty = true;
                }
            }
        }

        public SecurityIdentifier Sid { get; private set; }
        public string Path { get; internal set; }

        public BaseObjectLabel(ResourceType resourceType)
        {
            this.resourceType = resourceType;
        }

        public void Refresh()
        {
            SafeSecurityDescriptorBuffer pSecurityDescriptor;
            IntPtr pSidOwner, pSidGroup, pDacl, pSacl = IntPtr.Zero;

            using (SafeHandle handle = GetHandle(false))
            {
                UInt32 res = NativeMethods.GetSecurityInfo(handle, resourceType, LABEL_SECURITY_INFORMATION,
                    out pSidOwner, out pSidGroup, out pDacl, out pSacl, out pSecurityDescriptor);
                if (res != 0)
                    throw new Win32Exception((int)res, "GetSecurityInfo() failed");
            }

            using (pSecurityDescriptor)
            {
                aceFlags = AceFlags.None;
                accessMask = MandatoryLabelMask.None;
                Sid = null;

                if (pSacl != IntPtr.Zero)
                {
                    // Get the current revision for use when we set a new label ACE
                    NativeHelpers.ACL_REVISION_INFORMATION aclRevision = GetAclInformation<NativeHelpers.ACL_REVISION_INFORMATION>(pSacl);
                    revision = aclRevision.AclRevision;

                    NativeHelpers.ACL_SIZE_INFORMATION aclSize = GetAclInformation<NativeHelpers.ACL_SIZE_INFORMATION>(pSacl);

                    // While a SACL may contain multiple label ACEs, only the first is applied
                    for (int i = 0; i < aclSize.AceCount; i++)
                    {
                        IntPtr pAce = IntPtr.Zero;
                        if (!NativeMethods.GetAce(pSacl, (UInt32)i, out pAce))
                            throw new Win32Exception("GetAce() failed");

                        NativeHelpers.ACE_HEADER aceHeader = (NativeHelpers.ACE_HEADER)Marshal.PtrToStructure(pAce,
                            typeof(NativeHelpers.ACE_HEADER));
                        if (aceHeader.AceType == 0x11) // SYSTEM_MANDATORY_LABEL_ACE_TYPE
                        {
                            NativeHelpers.SYSTEM_MANDATORY_LABEL_ACE labelAce = (NativeHelpers.SYSTEM_MANDATORY_LABEL_ACE)Marshal.PtrToStructure(
                                pAce, typeof(NativeHelpers.SYSTEM_MANDATORY_LABEL_ACE));

                            aceFlags = aceHeader.AceFlags;
                            accessMask = labelAce.Mask;
                            Sid = new SecurityIdentifier(IntPtr.Add(pAce, Marshal.SizeOf(labelAce) - sizeof(UInt32)));
                            break;
                        }
                    }
                }

                label = ConvertSidToLabel(Sid);
            }
            isDirty = false;
        }

        public void Persist()
        {
            // No need to persist when no changes have been set
            if (!isDirty)
                return;

            // Build a new ACL that contains the label we wish to set
            // See https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_acl for definition
            int aclHeaderSize = 8;
            int aceSize = Label == MandatoryLabel.None
                ? 0
                : Marshal.SizeOf(typeof(NativeHelpers.SYSTEM_MANDATORY_LABEL_ACE)) - sizeof(UInt32) + Sid.BinaryLength;

            int aclSize = aclHeaderSize + aceSize;
            using (SafeMemoryBuffer pNewSacl = new SafeMemoryBuffer(aclSize))
            {
                if (!NativeMethods.InitializeAcl(pNewSacl, (UInt32)aclSize, revision))
                    throw new Win32Exception("InitializeAcl() failed");

                using (SafeMemoryBuffer pNewAce = new SafeMemoryBuffer(aceSize))
                {
                    if (Label != MandatoryLabel.None)
                    {
                        byte[] sidBytes = new byte[Sid.BinaryLength];
                        Sid.GetBinaryForm(sidBytes, 0);

                        using (SafeMemoryBuffer pSid = new SafeMemoryBuffer(sidBytes.Length))
                        {
                            Marshal.Copy(sidBytes, 0, pSid.DangerousGetHandle(), sidBytes.Length);
                            if (!NativeMethods.AddMandatoryAce(pNewSacl, revision, aceFlags, accessMask, pSid))
                                throw new Win32Exception("AddMandatoryAce() failed");
                        }
                    }

                    UInt32 res;
                    using (SafeHandle handle = GetHandle(true))
                        res = NativeMethods.SetSecurityInfo(handle, resourceType, LABEL_SECURITY_INFORMATION,
                            IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, pNewSacl.DangerousGetHandle());
                    if (res != 0)
                        throw new Win32Exception("SetSecurityInfo() failed");
                }

            }
            isDirty = false;
        }

        internal abstract SafeHandle GetHandle(bool write);

        private SecurityIdentifier ConvertLabelToSid(MandatoryLabel label)
        {
            switch (label)
            {
                case MandatoryLabel.None:
                    return null;
                case MandatoryLabel.Untrusted:
                    return new SecurityIdentifier("S-1-16-0");
                case MandatoryLabel.Low:
                    return new SecurityIdentifier("S-1-16-4096");
                case MandatoryLabel.Medium:
                    return new SecurityIdentifier("S-1-16-8192");
                case MandatoryLabel.High:
                    return new SecurityIdentifier("S-1-16-12288");
                case MandatoryLabel.System:
                    return new SecurityIdentifier("S-1-16-16384");
                case MandatoryLabel.ProtectedProcess:
                    return new SecurityIdentifier("S-1-16-20480");
                case MandatoryLabel.SecureProcess:
                    return new SecurityIdentifier("S-1-16-28672");
                default:
                    throw new ArgumentException(String.Format("Cannot convert {0} mandatory label to SID",
                        label.ToString()));
            }
        }

        private MandatoryLabel ConvertSidToLabel(SecurityIdentifier sid)
        {
            if (sid == null)
                return MandatoryLabel.None;

            switch (sid.Value)
            {
                case "S-1-16-0":
                    return MandatoryLabel.Untrusted;
                case "S-1-16-4096":
                    return MandatoryLabel.Low;
                case "S-1-16-8192":
                    return MandatoryLabel.Medium;
                case "S-1-16-12288":
                    return MandatoryLabel.High;
                case "S-1-16-16384":
                    return MandatoryLabel.System;
                case "S-1-16-20480":
                    return MandatoryLabel.ProtectedProcess;
                case "S-1-16-28672":
                    return MandatoryLabel.SecureProcess;
                default:
                    return MandatoryLabel.Unknown;
            }
        }

        private T GetAclInformation<T>(IntPtr acl)
        {
            NativeHelpers.ACL_INFORMATION_CLASS infoClass = typeof(T) == typeof(NativeHelpers.ACL_REVISION_INFORMATION)
                ? NativeHelpers.ACL_INFORMATION_CLASS.AclRevisionInformation
                : NativeHelpers.ACL_INFORMATION_CLASS.AclSizeInformation;

            int infoLength = Marshal.SizeOf(typeof(T));
            using (SafeMemoryBuffer pAclInfo = new SafeMemoryBuffer(infoLength))
            {
                if (!NativeMethods.GetAclInformation(acl, pAclInfo, (UInt32)infoLength, infoClass))
                    throw new Win32Exception(String.Format("GetAclInformation({0}) failed", infoClass.ToString()));

                return (T)Marshal.PtrToStructure(pAclInfo.DangerousGetHandle(), typeof(T));
            }
        }
    }

    public class FileObjectLabel : BaseObjectLabel
    {
        private const UInt32 FILE_FLAG_BACKUP_SEMANTICS = 0x02000000;

        public FileObjectLabel(string path) : base(ResourceType.FileObject)
        {
            this.Path = path;
            Refresh();
        }

        internal override SafeHandle GetHandle(bool write)
        {
            List<string> privileges = new List<string> { "SeBackupPrivilege" };
            FileSystemRights rights = FileSystemRights.ReadPermissions;

            if (write)
            {
                // SeRelabelPrivilege is only required to set a label that's higher than the access token's integrity
                // level, we opportunistically try and enable the privilege if we need write access
                privileges.AddRange(new string[2] { "SeRestorePrivilege", "SeRelabelPrivilege" });
                rights |= FileSystemRights.TakeOwnership;
            }

            using (new PrivilegeEnabler(privileges.ToArray()))
            {
                SafeFileHandle handle = NativeMethods.CreateFileW(Path, rights, FileShare.ReadWrite, IntPtr.Zero,
                    FileMode.Open, FILE_FLAG_BACKUP_SEMANTICS, IntPtr.Zero);

                if (handle.IsInvalid)
                    throw new Win32Exception(String.Format("CreateFileW({0}) failed", Path));

                return handle;
            }
        }
    }

    public enum MandatoryLabel
    {
        None,
        Untrusted,  // S-1-16-0
        Low,  // S-1-16-4096
        Medium,  // S-1-16-8192
        High,  // S-1-16-1228
        System,  // S-1-16-16384
        ProtectedProcess,  // S-1-16-20480
        SecureProcess,  // S-1-16-28672
        Unknown,
    }

    [Flags]
    public enum MandatoryLabelMask
    {
        None = 0x0,
        NoWriteUp = 0x1,
        NoReadUp = 0x2,
        NoExecuteUp = 0x4,
    }
}
'@

Function Get-IntegrityLabel {
    <#
    .SYNOPSIS
    Gets the integrity label and policy for the object specified.

    .DESCRIPTION
    This cmdlet can be used to get the integrity label information for a file
    or folder. The output object can be used as the input to Set-IntegrityLabel
    and Remove-IntegrityLabel. You can also manually manipulate the label,
    policy and the flags on the object itself.

    .PARAMETER Path
    [String] The path to the resource to get the label info for.

    .INPUTS
    [String] The path to get the label for.

    .OUTPUTS
    [PSIntegrity.BaseObjectLabel] An object that implements the BaseObjectLabel
    class. This object can be used as the input to Set-IntegrityLabel and
    Remove-IntegrityLabel or even used directly to manage the label, policy,
    and flags on the object.

    .EXAMPLE
    # Get the integrity label for a folder
    Get-IntegrityLabel -Path C:\Windows

    .NOTES
    Currently only a file system object is supported by this cmdlet.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true)]
        [String]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        $error_args = @{
            Message = "Cannot find path '$Path' because it does not exist."
            Category = "ObjectNotFound"
            ErrorId = "PathNotFound,PSIntegrity"
            CategoryReason = "ItemNotFoundException"
            CategoryTargetName = $Path
            CategoryTargetType = $Path.GetType().FullName
        }
        Write-Error @error_args
        return
    }

    return New-Object -TypeName PSIntegrity.FileObjectLabel -ArgumentList $Path
}

Function Remove-IntegrityLabel {
    <#
    .SYNOPSIS
    Removes an integrity label and policy from the object specified.

    .DESCRIPTION
    This cmdlet can be used to easily remove an integrity label and it's policy
    from an object. You can also use Set-IntegrityLabel -Label None to achieve
    the same thing.

    .PARAMETER InputObject
    [PSIntegrity.BaseObjectLabel] A class object that implements
    PSIntegrity.BaseObjectLabel. This can be retrieved by calling
    Get-IntegrityLabel or the return object of this cmdlet when using the
    -PassThru switch for this cmdlet. This parameter is mutually exclusive to
    Path.

    .PARAMETER Path
    [String] The path to the resource to remove the integrity level. This
    parameter is mutually exclusive to InputObject.

    .PARAMETER PassThru
    [Switch] Will output the BaseObjectLabel used when removing the label.

    .INPUTS
    [PSIntegrity.BaseObjectLabel] An object that implements
    PSIntegirty.BaseObjectLabel.

    .OUTPUTS
    None when -PassThru is not specified, otherwise an object that implements
    [PSIntegrity.BaseObjectLabel].

    .EXAMPLE
    # Remove an integrity label from a file
    Remove-IntegrityLabel -Path C:\Users\test\file.txt

    # Remove an integrity label from a file and get the label object back
    $label = Remove-IntegrityLabel -Path C:\Users\test\file.txt -PassThru

    # Remove an integrity label using InputObject
    Remove-IntegrityLabel -InputObject $label
    #>
    [CmdletBinding(SupportsShouldProcess=$true, DefaultParameterSetName="Path")]
    Param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true,
            ParameterSetName="InputObject")]
        [PSIntegrity.BaseObjectLabel]$InputObject,
        [Parameter(Position=0, Mandatory=$true, ParameterSetName="Path")]
        [String]$Path,
        [Switch]$PassThru
    )

    if ($PSCmdlet.ParameterSetName -eq "Path") {
        $InputObject = Get-IntegrityLabel -Path $Path
    }

    if ($InputObject.Label -ne [PSIntegrity.MandatoryLabel]::None) {
        if ($PSCmdlet.ShouldProcess($InputObject.Path, "Remove Label $($InputObject.Label)")) {
            $InputObject.Label = [PSIntegrity.MandatoryLabel]::None
            $InputObject.Persist()
        }
    }

    if ($PassThru) {
        Write-Output -InputObject $InputObject
    }
}

Function Set-IntegrityLabel {
    <#
    .SYNOPSIS
    Sets the mandatory integrity level ACE for a resource.

    .DESCRIPTION
    This cmdlet can be used to set the mandatory integrity level ACE of a
    resource as well as the AceFlags and AccessMask for that ACE.

    .PARAMETER InputObject
    [PSIntegrity.BaseObjectLabel] A class object that implements
    PSIntegrity.BaseObjectLabel. This can be retrieved by calling
    Get-IntegrityLabel or the return object of this cmdlet when using the
    -PassThru switch for this cmdlet. This parameter is mutually exclusive to
    Path.

    .PARAMETER Path
    [String] The path to the resource to set the integrity level. This
    parameter is mutually exclusive to InputObject.

    .PARAMETER Label
    [PSIntegrity.MandatoryLabel] The label to set on the resource. Use None to
    remove a label (or the Remove-IntegrityLabel cmdlet). The Unknown label
    cannot be set as it is only used if an unknown label has been set by
    another tool. You can also only set a label that is equal to or less than
    the current process's label which is typicaly Medium for a standard process
    or High for an admin process. To set a high label you will need the
    SeRelabelPrivilege privilege on the running account.

    .PARAMETER Flags
    [System.Security.AccessControl.AceFlags] Sets the AceFlags for the label
    ACE. These flags control the inheritance and auditing behaviour of the ACE.
    You cannot set the InheritOnly flag for a label ACE.

    .PARAMETER AccessMask
    [PSIntegrity.MandatoryLabelMask] Set the access mask for the label which
    controls the label policy set on the resource. Set to None to remove the
    access mask.

    .PARAMETER PassThru
    [Switch] Will output the BaseObjectLabel used to set the label.

    .INPUTS
    [PSIntegrity.BaseObjectLabel] An object that implements
    PSIntegirty.BaseObjectLabel.

    .OUTPUTS
    None when -PassThru is not specified, otherwise an object that implements
    [PSIntegrity.BaseObjectLabel].

    .EXAMPLE
    # Set a High integrity label to a file
    Set-IntegrityLabel -Path C:\Users\test\file.txt -Label High

    # Set a High integrity label to Low and get the label object back
    $label = Set-IntegrityLabel -Path C:\Users\test\file.txt -Label Low -PassThru

    # Remove an integrity label using InputObject
    Set-IntegrityLabel -InputObject $label -Label None

    # Set no write/read/execute policy for the label
    $label | Set-IntegrityLabel -Label High -AccessMask NoWriteUp, NoReadUp, NoExecuteUp

    # Ensure the label is inherited to all child folders and files
    Set-IntegrityLabel -Path C:\application -Label Low -Flags ContainerInherit, ObjectInherit

    .NOTES
    You cannot set a label that is higher than the one on the current access
    token unless the user has the SeRelabelPrivilege enabled
    https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/modify-an-object-label.
    #>
    [CmdletBinding(SupportsShouldProcess=$true, DefaultParameterSetName="Path")]
    Param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true,
            ParameterSetName="InputObject")]
        [PSIntegrity.BaseObjectLabel]$InputObject,
        [Parameter(Position=0, Mandatory=$true, ParameterSetName="Path")]
        [String]$Path,
        [Parameter(Position=1, Mandatory=$true)]
        [PSIntegrity.MandatoryLabel]$Label,
        [System.Security.AccessControl.AceFlags]$Flags,
        [PSIntegrity.MandatoryLabelMask]$AccessMask,
        [Switch]$PassThru
    )

    if ($PSCmdlet.ParameterSetName -eq "Path") {
        $InputObject = Get-IntegrityLabel -Path $Path
    }

    $changes = [System.Collections.Generic.List`1[String]]@()
    if ($null -ne $Flags -and $Flags -ne $InputObject.AceFlags) {
        if ($Flags.HasFlag([System.Security.AccessControl.AceFlags]::InheritOnly)) {
            $error_args = @{
                Message = "Cannot set the InheritOnly AceFlags for an integrity label."
                Category = "InvalidOperation"
                ErrorId = "InvalidOperation,PSIntegrity"
                CategoryReason = "ArgumentException"
                CategoryTargetName = $Flags
                CategoryTargetType = $Flags.GetType().FullName
            }
            Write-Error @error_args
            return
        }

        $change = "AceFlags from $($InputObject.AceFlags) to $Flags"
        Write-Verbose -Message "Changing $change"
        $InputObject.AceFlags = $Flags
        $changes.Add($change) > $null
    }

    if ($InputObject.Label -ne $Label) {
        $change = "Label from $($InputObject.Label) to $Label"
        Write-Verbose -Message "Changing $change"
        $InputObject.Label = $Label
        $changes.Add($change) > $null
    }

    if ($null -ne $AccessMask -and $AccessMask -ne $InputObject.AccessMask) {
        $change = "AcessMask from $($InputObject.AccessMask) to $AccessMask"
        Write-Verbose -Message "Changing $change"
        $InputObject.AccessMask = $AccessMask
        $changes.Add($change) > $null
    }

    if ($changes.Count -gt 0) {
        if ($PSCmdlet.ShouldProcess($InputObject.Path, "Persist changes to object: $($changes -join ", ")")) {
            $InputObject.Persist()
        } else {
            # If we don't do the ACE change, we refresh to get the original values back
            $InputObject.Refresh()
        }
    }

    if ($PassThru) {
        Write-Output -InputObject $InputObject
    }
}

Export-ModuleMember -Function Get-IntegrityLabel, Remove-IntegrityLabel, Set-IntegrityLabel
