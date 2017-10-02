using BinDeps

@BinDeps.setup

# 32-bit
libmetis = library_dependency("libmetis", aliases=["libmetis5"]) # The default library in all the systems is compiled with 32 bit integer and floats

if is_windows()
    using WinRPM
    provides(WinRPM.RPM, "metis", libmetis, os = :Windows)
end

if is_apple()
    if Pkg.installed("Homebrew") === nothing
        error("Homebrew package not installed, please run Pkg.add(\"Homebrew\")")  end
    using Homebrew
    provides(Homebrew.HB, "metis", libmetis, os = :Darwin)
end

provides(AptGet, "libmetis5", libmetis)

provides(Yum, "metis-5.1.0", libmetis)

provides(Sources, URI("http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz"), libmetis)

metisname = "metis-5.1.0"

provides(Sources, URI("http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz"), libmetis)


depsdir = BinDeps.depsdir(libmetis)
prefix = joinpath(depsdir,"usr")
srcdir = joinpath(depsdir,"src",metisname)

provides(SimpleBuild,
         (@build_steps begin
             GetSources(libmetis)
             (@build_steps begin
	         ChangeDirectory(srcdir)
	         (@build_steps begin
	             `make config shared=1 prefix=$prefix`
	             `make`
	             `make install`
                 end)
	     end)
         end), libmetis, os=:Unix)

# 64-bit
# Only done for UNIX
libmetis64 = library_dependency("libmetis64")

provides(Sources, URI("http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz"), libmetis64)
metis64_depsdir = BinDeps.depsdir(libmetis64)
metis64_prefix = joinpath(metis64_depsdir, "usr")
metis64_srcdir = joinpath(metis64_depsdir, "src", metisname)         
         
provides(SimpleBuild,
         (@build_steps begin
             GetSources(libmetis64)
             (@build_steps begin
	         ChangeDirectory(metis64_srcdir)
	         (@build_steps begin
                 `cp ../../metis.h $metis64_srcdir/include/`
	             `make config shared=1 prefix=$metis64_prefix`
	             `make`
	             `make install`
	             `mv ../../usr/lib/libmetis.so ../../usr/lib/libmetis64.so`
                 end)
	     end)
         end), libmetis64, os=:Unix)

@BinDeps.install Dict([(:libmetis => :libmetis), (:libmetis64 => :libmetis64)])
