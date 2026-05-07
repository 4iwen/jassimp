#if OS == .WINDOWS {
    #load "bindings/windows/windows.jai";
    libcpmt :: #library,system,link_always "libcpmt";
} else #if OS == .MACOS {
    #load "bindings/macos/macos.jai";
} else {
    #assert false "this OS is not currently supported. You must generate bindings for it. Check the README for information.";
}
