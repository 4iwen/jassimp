#run build();

build :: () {
    set_build_options_dc(.{do_output = false});

    options := get_build_options();
    args := options.compile_time_command_line;

    if !generate_assimp_bindings(args) {
        compiler_set_workspace_status(.FAILED);
    }
}

DECLARATIONS_TO_OMIT :: string.[
    "aiGetMaterialFloat",   // not exported in assimp
    "aiGetMaterialInteger", // not exported in assimp
];

ENUMS_TO_OMIT :: string.[];

generate_assimp_bindings :: (args: [] string) -> bool {
    no_compile := array_find(args, "-no_compile");
    compile_debug := array_find(args, "-debug");

    #if OS == .WINDOWS {
        make_directory_if_it_does_not_exist("bindings");
        make_directory_if_it_does_not_exist("bindings/windows");
        make_directory_if_it_does_not_exist("bindings/windows/x64");

        if !no_compile {
            if !compile_assimp_windows(compile_debug) {
                return false;
            }
        }
    } else #if OS == .MACOS {
        make_directory_if_it_does_not_exist("bindings");
        make_directory_if_it_does_not_exist("bindings/macos");
    }

    output_filename: string;
    opts: Generate_Bindings_Options;
    {
        using opts;

        #if OS == .WINDOWS {
            output_filename = "bindings/windows/windows.jai";
            array_add(*library_search_paths, "bindings/windows/x64");

            footer = FOOTER_WIN;
            generate_library_declarations = false;

            lib: Library;
            lib.filename = "assimp";
            array_add(*libraries, lib);
        } else #if OS == .MACOS {
            strip_flags = 0;
            output_filename = "bindings/macos/macos.jai";
            array_add(*library_search_paths, "bindings/macos/arm64");

            footer = FOOTER_MACOS;
            generate_library_declarations = false;

            lib: Library;
            lib.filename = "libassimp";
            array_add(*libraries, lib);

            array_add(
                *path_fragments_to_treat_as_non_system_paths,
                "include/assimp"
            );
        } else {
            assert(false, "this OS is currently unsupported. You might be able to add support for it though!");
        }

        array_add(*include_paths, "include");
        array_add(*source_files, "include/assimp/aabb.h");
        array_add(*source_files, "include/assimp/anim.h");
        array_add(*source_files, "include/assimp/camera.h");
        array_add(*source_files, "include/assimp/light.h");
        array_add(*source_files, "include/assimp/material.h");
        array_add(*source_files, "include/assimp/mesh.h");
        array_add(*source_files, "include/assimp/metadata.h");
        array_add(*source_files, "include/assimp/texture.h");
        array_add(*source_files, "include/assimp/cimport.h");
        array_add(*source_files, "include/assimp/cexport.h");
        array_add(*source_files, "include/assimp/scene.h");
        array_add(*source_files, "include/assimp/postprocess.h");
        array_add(*source_files, "include/assimp/defs.h");
        array_add(*source_files, "include/assimp/types.h");
        array_add(*source_files, "include/assimp/vector2.h");
        array_add(*source_files, "include/assimp/vector3.h");
        array_add(*source_files, "include/assimp/color4.h");
        array_add(*source_files, "include/assimp/matrix3x3.h");
        array_add(*source_files, "include/assimp/matrix4x4.h");
        array_add(*source_files, "include/assimp/quaternion.h");
        array_add(*source_files, "include/assimp/texture.h");
        array_add(*source_files, "include/assimp/mesh.h");
        array_add(*source_files, "include/assimp/aabb.h");
        array_add(*source_files, "include/assimp/light.h");
        array_add(*source_files, "include/assimp/camera.h");
        array_add(*source_files, "include/assimp/material.h");
        array_add(*source_files, "include/assimp/anim.h");
        array_add(*source_files, "include/assimp/metadata.h");
        array_add(*source_files, "include/assimp/importerdesc.h");
        array_add(*source_files, "include/assimp/cimport.h");
        array_add(*source_files, "include/assimp/scene.h");
        array_add(*source_files, "include/assimp/postprocess.h");

        visitor = custom_visitor;
        generate_compile_time_struct_checks = false;
    }

    return generate_bindings(opts, output_filename);
}

compile_assimp_windows :: (compile_debug: bool) -> bool {
    source_dir := "assimp";
    source_cmake := tprint("%/CMakeLists.txt", source_dir);
    if !file_exists(source_cmake) {
        compiler_report(tprint("jassimp Windows generation requires the assimp submodule at '%'.\n", source_dir));
        compiler_report("Run 'git submodule update --init --recursive' before generating.\n");
        return false;
    }

    build_type := ifx compile_debug then "Debug" else "Release";
    build_type_upper := ifx compile_debug then "DEBUG" else "RELEASE";
    build_dir := "bindings/windows/build";
    stage_dir := "bindings/windows/stage";
    output_dir := "bindings/windows/x64";

    if !recreate_directory(build_dir) return false;
    if !recreate_directory(stage_dir) return false;
    if !recreate_directory(output_dir) return false;

    config_command: [..] string;
    array_add(*config_command, "cmake");
    array_add(*config_command, "-S", source_dir);
    array_add(*config_command, "-B", build_dir);
    array_add(*config_command, "-G", "Visual Studio 17 2022");
    array_add(*config_command, "-A", "x64");
    array_add(*config_command, "-DASSIMP_WARNINGS_AS_ERRORS=ON");
    array_add(*config_command, "-DASSIMP_BUILD_ASSIMP_TOOLS=OFF");
    array_add(*config_command, "-DBUILD_SHARED_LIBS=OFF");
    array_add(*config_command, "-DASSIMP_BUILD_ZLIB=ON");
    array_add(*config_command, "-DASSIMP_BUILD_TESTS=OFF");
    array_add(*config_command, "-DASSIMP_INSTALL=OFF");
    array_add(*config_command, "-DUSE_STATIC_CRT=OFF");
    array_add(*config_command, "-DASSIMP_BUILD_ASSIMP_VIEW=OFF");
    array_add(*config_command, tprint("-DCMAKE_BUILD_TYPE=%", build_type));
    array_add(*config_command, tprint("-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY=%", stage_dir));
    array_add(*config_command, tprint("-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=%", stage_dir));
    array_add(*config_command, tprint("-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=%", stage_dir));
    array_add(*config_command, tprint("-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY_%=%", build_type_upper, stage_dir));
    array_add(*config_command, tprint("-DCMAKE_LIBRARY_OUTPUT_DIRECTORY_%=%", build_type_upper, stage_dir));
    array_add(*config_command, tprint("-DCMAKE_RUNTIME_OUTPUT_DIRECTORY_%=%", build_type_upper, stage_dir));

    if run_command(..config_command).exit_code != 0 {
        return false;
    }

    build_command: [..] string;
    array_add(*build_command, "cmake", "--build", build_dir, "--config", build_type, "--parallel", "10");
    if run_command(..build_command).exit_code != 0 {
        return false;
    }

    assimp_lib := find_windows_build_artifact(stage_dir, "assimp", ".lib");
    zlib_lib := find_windows_build_artifact(stage_dir, "zlibstatic", ".lib", exact_name = true);
    if !assimp_lib || !zlib_lib {
        compiler_report(tprint("Failed to locate built Windows assimp static libraries in '%'.\n", stage_dir));
        return false;
    }

    success := copy_file(assimp_lib, tprint("%/assimp.lib", output_dir));
    success &&= copy_file(zlib_lib, tprint("%/zlibstatic.lib", output_dir));
    return success;
}

find_windows_build_artifact :: (root: string, name_prefix: string, name_suffix: string, exact_name := false) -> string {
    Find_Data :: struct {
        root: string;
        name_prefix: string;
        name_suffix: string;
        exact_name: bool;
        found: string;
    }

    data := Find_Data.{
        root = root,
        name_prefix = name_prefix,
        name_suffix = name_suffix,
        exact_name = exact_name,
    };

    visitor :: (info: *File_Visit_Info, data: *Find_Data) {
        if data.found return;
        if info.is_directory return;

        if data.exact_name {
            if info.short_name == tprint("%%", data.name_prefix, data.name_suffix) {
                data.found = copy_string(info.full_name);
            }
            return;
        }

        if !starts_with(info.short_name, data.name_prefix) return;
        if !ends_with(info.short_name, data.name_suffix) return;
        if contains(info.short_name, ".dll") return;
        if contains(info.short_name, ".exp") return;
        data.found = copy_string(info.full_name);
    }

    visit_files(root, true, *data, visitor);
    return data.found;
}

custom_visitor :: (decl: *Declaration, parent_decl: *Declaration) -> Declaration_Visit_Result {
    if parent_decl return .RECURSE;

    if array_find(DECLARATIONS_TO_OMIT, decl.name) {
        decl.decl_flags |= .OMIT_FROM_OUTPUT;
        return .STOP;
    }

    if decl.kind == .ENUM && array_find(ENUMS_TO_OMIT, decl.name) {
        decl.decl_flags |= .OMIT_FROM_OUTPUT;
        return .STOP;
    }

    return .RECURSE;
}

recreate_directory :: (name: string) -> bool {
    if file_exists(name) {
        if !delete_directory(name) {
            return false;
        }
    }

    return make_directory_if_it_does_not_exist(name, recursive = true);
}

#scope_file

#import "Basic";
#import "Compiler";
#import "Bindings_Generator";
#import "File";
#import "File_Utilities";
#import "Process";
#import "String";

FOOTER_WIN :: #string END
zlib :: #library,no_dll,link_always "x64/zlibstatic";
assimp :: #library,no_dll "x64/assimp";
END

FOOTER_MACOS :: #string END
libassimp :: #library,no_dll "arm64/libassimp";
libcxx :: #library,system,link_always "libc++";
libz :: #library,system,link_always "libz";
END
