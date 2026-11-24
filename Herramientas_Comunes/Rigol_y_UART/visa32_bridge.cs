using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

internal static class Visa32Bridge
{
    private const string VisaDll = "visa32.dll";
    private const int Success = 0;
    private const uint TimeoutMs = 10000;
    private const uint AttrTimeout = 0x3FFF001A;
    private const uint AttrTermChar = 0x3FFF0018;
    private const uint AttrTermCharEnable = 0x3FFF0038;

    private static uint resourceManager;
    private static uint instrument;

    [DllImport(VisaDll, CharSet = CharSet.Ansi)]
    private static extern int viOpenDefaultRM(out uint session);

    [DllImport(VisaDll, CharSet = CharSet.Ansi)]
    private static extern int viFindRsrc(uint session, string expression,
        out uint findList, out uint count, StringBuilder description);

    [DllImport(VisaDll, CharSet = CharSet.Ansi)]
    private static extern int viFindNext(uint findList, StringBuilder description);

    [DllImport(VisaDll, CharSet = CharSet.Ansi)]
    private static extern int viOpen(uint session, string resourceName,
        uint accessMode, uint timeout, out uint resource);

    [DllImport(VisaDll)]
    private static extern int viClose(uint resource);

    [DllImport(VisaDll)]
    private static extern int viSetAttribute(uint resource, uint attribute, uint value);

    [DllImport(VisaDll)]
    private static extern int viWrite(uint resource, byte[] buffer,
        uint count, out uint returnCount);

    [DllImport(VisaDll)]
    private static extern int viRead(uint resource, byte[] buffer,
        uint count, out uint returnCount);

    private static void Check(int status, string operation)
    {
        if (status < Success)
            throw new InvalidOperationException(operation + " fallo (VISA " + status + ").");
    }

    private static string Encode(byte[] value)
    {
        return Convert.ToBase64String(value);
    }

    private static string Encode(string value)
    {
        return Encode(Encoding.UTF8.GetBytes(value ?? ""));
    }

    private static string Decode(string value)
    {
        return Encoding.UTF8.GetString(Convert.FromBase64String(value));
    }

    private static void Reply(string kind, string payload)
    {
        Console.Out.WriteLine(kind + "\t" + payload);
        Console.Out.Flush();
    }

    private static void EnsureManager()
    {
        if (resourceManager != 0) return;
        Check(viOpenDefaultRM(out resourceManager), "viOpenDefaultRM");
    }

    private static List<string> ListResources()
    {
        EnsureManager();
        var result = new List<string>();
        uint findList;
        uint count;
        var description = new StringBuilder(512);
        int status = viFindRsrc(resourceManager, "?*INSTR", out findList, out count, description);
        if (status < Success) return result;
        try
        {
            if (count > 0) result.Add(description.ToString());
            for (uint index = 1; index < count; index++)
            {
                description.Length = 0;
                Check(viFindNext(findList, description), "viFindNext");
                result.Add(description.ToString());
            }
        }
        finally
        {
            viClose(findList);
        }
        return result;
    }

    private static void Open(string resourceName)
    {
        EnsureManager();
        if (instrument != 0) viClose(instrument);
        Check(viOpen(resourceManager, resourceName, 0, TimeoutMs, out instrument), "viOpen");
        Check(viSetAttribute(instrument, AttrTimeout, TimeoutMs), "timeout");
        Check(viSetAttribute(instrument, AttrTermChar, 10), "termchar");
        Check(viSetAttribute(instrument, AttrTermCharEnable, 1), "termchar enable");
    }

    private static void Write(string command)
    {
        if (instrument == 0) throw new InvalidOperationException("No hay instrumento abierto.");
        byte[] data = Encoding.ASCII.GetBytes(command.TrimEnd('\r', '\n') + "\n");
        uint written;
        Check(viWrite(instrument, data, (uint)data.Length, out written), "viWrite");
        if (written != data.Length) throw new InvalidOperationException("Escritura VISA incompleta.");
    }

    private static byte[] ReadChunk(int capacity)
    {
        var buffer = new byte[capacity];
        uint count;
        Check(viRead(instrument, buffer, (uint)buffer.Length, out count), "viRead");
        if (count == buffer.Length) return buffer;
        var result = new byte[count];
        Buffer.BlockCopy(buffer, 0, result, 0, (int)count);
        return result;
    }

    private static byte[] ReadExact(int count)
    {
        var result = new byte[count];
        int offset = 0;
        while (offset < count)
        {
            var buffer = new byte[count - offset];
            uint received;
            Check(viRead(instrument, buffer, (uint)buffer.Length, out received), "viRead exact");
            if (received == 0) throw new InvalidOperationException("Respuesta binaria incompleta.");
            Buffer.BlockCopy(buffer, 0, result, offset, (int)received);
            offset += (int)received;
        }
        return result;
    }

    private static string QueryText(string command)
    {
        Write(command);
        return Encoding.ASCII.GetString(ReadChunk(1048576)).TrimEnd('\r', '\n');
    }

    private static byte[] QueryBinary(string command)
    {
        Write(command);
        byte[] header = ReadExact(2);
        if (header[0] != (byte)'#' || header[1] < (byte)'1' || header[1] > (byte)'9')
            throw new InvalidOperationException("Cabecera binaria IEEE 488.2 invalida.");
        int digits = header[1] - (byte)'0';
        int length = int.Parse(Encoding.ASCII.GetString(ReadExact(digits)));
        return ReadExact(length);
    }

    private static void CloseAll()
    {
        if (instrument != 0) { viClose(instrument); instrument = 0; }
        if (resourceManager != 0) { viClose(resourceManager); resourceManager = 0; }
    }

    public static int Main()
    {
        try
        {
            string line;
            while ((line = Console.ReadLine()) != null)
            {
                try
                {
                    string[] parts = line.Split(new[] { '\t' }, 2);
                    string operation = parts[0].ToUpperInvariant();
                    string argument = parts.Length == 2 ? Decode(parts[1]) : "";
                    if (operation == "LIST")
                        Reply("OK", Encode(string.Join("\n", ListResources().ToArray())));
                    else if (operation == "OPEN")
                    {
                        Open(argument);
                        Reply("OK", Encode(""));
                    }
                    else if (operation == "QUERY")
                        Reply("OK", Encode(QueryText(argument)));
                    else if (operation == "WRITE")
                    {
                        Write(argument);
                        Reply("OK", Encode(""));
                    }
                    else if (operation == "BINARY")
                        Reply("OK", Encode(QueryBinary(argument)));
                    else if (operation == "CLOSE")
                    {
                        CloseAll();
                        Reply("OK", Encode(""));
                        return 0;
                    }
                    else
                        throw new InvalidOperationException("Operacion desconocida: " + operation);
                }
                catch (Exception error)
                {
                    Reply("ERR", Encode(error.Message));
                }
            }
            return 0;
        }
        finally
        {
            CloseAll();
        }
    }
}
