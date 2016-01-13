RUST on the day I am writing this has no good support of x86 Android, and no official support of x86_64 Android.
However, I have a very powerful Nokia N1 tablet, and with TERMUX installed, which is a very good mobile platform for rust programming.

So, I decide to cross compile rustc to make it work on x86_64-linux-android target.
After may times failure, I found japaric/ruststrap scripts are the most valuable baseline.

In the latest rust nightly build, following code changes are needed to introduce a new target:
1) target makefile under mk/cfg
2) target specification under src/librustc_back/target, which includes two files - one new target triplet definition, and one loading control
3) usually some os/arch/target related changes under src/libstd/os

Only this file, and the files under amd64 directories are needed. 
The ARM information is only for reference.

Unfortuantely, the running of "rustc" still failed on x86_64 Android, because of the missing support of ELF x86_64 thread local storage re-location.
There is some interesting discussion in D language about the same problem: https://github.com/D-Programming-Language/dmd/pull/3643#issuecomment-45479519

Some progress:
  Latest development version of LLVM incldues emulated ELS support to workaround the Android linker problem.
  https://llvm.org/bugs/show_bug.cgi?id=23566
  
  Compiling the latest LLVM requires workaround for std::to-string in Android NDK:
  http://stackoverflow.com/questions/22774009/android-ndk-stdto-string-support


# License

All the scripts/patches in this repository are licensed under the MIT license.

See LICENSE-MIT for more details.

[1.0.0]: https://www.dropbox.com/sh/qfbt03ys2qkhsxs/AAB-bhnmUMG8ihNPcrz5twRYa/1.0.0?dl=0
[1.1.0]: https://www.dropbox.com/sh/qfbt03ys2qkhsxs/AAAkav_PiigmCnwCU4CrMNjHa/1.1.0?dl=0
[1.2.0-beta]: https://www.dropbox.com/sh/qfbt03ys2qkhsxs/AAAmWy67Hx4znnHkG1TKzrOPa/1.2.0-beta?dl=0
[Nightlies]: https://www.dropbox.com/sh/qfbt03ys2qkhsxs/AACxFoD1OrxDXURzj5wX0IYUa?dl=0
