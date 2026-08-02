#![feature(try_blocks)]

mod abi;
mod api;
mod bridge;
mod dlfcn;
mod filter;
mod logs;

use api::ZygiskModule;
use bridge::ApiBridge;

use public::{
    properties::getprop,
    zygote::SpecializeArgs
};

use std::{
    fs::File,
    pin::Pin,
    path::Path,
    sync::Mutex
};

use log::error;

struct ZygiskContext {
    args: Vec<u64>,
    module: Option<Pin<Box<ZygiskModule>>>
}

impl ZygiskContext {
    fn new() -> Self {
        Self {
            args: Vec::new(),
            module: None
        }
    }
}

struct ZygiskCompat {
    ctx: Mutex<ZygiskContext>
}

impl ZygiskCompat {
    fn new() -> Self {
        Self { ctx: Mutex::new(ZygiskContext::new()) }
    }
}

impl ApiBridge for ZygiskCompat {
    fn on_dlopen(&self) {
        let arch = getprop("ro.product.cpu.abi");
        let base_path = Path::new("/data/adb/modules");
        let vector_exists: bool = base_path.join("zygisk_vector").exists() && !base_path.join("zygisk_vector/disable").exists();
        let target = if base_path.join("zygisk_lsposed").exists() && !base_path.join("zygisk_lsposed/disable").exists() {
            if vector_exists {
                return
            } else {
                error!("lsposed and vector coexist");
                base_path.join(format!("zygisk_lsposed/zygisk/{}.so", arch))
            }
        } else if vector_exists {
            base_path.join(format!("zygisk_vector/zygisk/{}.so", arch))
        } else {
            error!("lsposed and vector not found");
            return
        };
        let res : anyhow::Result<()> = try {
            let library = File::open(target).unwrap();
            let mut lock = self.ctx.lock().unwrap();
            lock.module.replace(ZygiskModule::new("LSPosed", library.into())?);
        };

        if let Err(err) = res {
            error!("failed to load module: {err}");
        }
    }

    fn on_specialize(&self, args: SpecializeArgs) {
        let env = args.env();

        let mut lock = self.ctx.lock().unwrap();

        if let Some(module) = &lock.module {
            module.entry(env);

            if args.is_system_server() {
                module.prss(&module.args_server(&args));
            } else {
                module.pras(&module.args_app(&args));
            }

            lock.args.extend(args.as_slice());
        }
    }

    fn after_specialize(&self) {
        let lock = self.ctx.lock().unwrap();

        if let Some(module) = &lock.module {
            let args = &lock.args;
            let args= SpecializeArgs::from(args.as_ptr() as *mut _);

            if args.is_system_server() {
                module.poss(&module.args_server(&args));
            } else {
                module.poas(&module.args_app(&args));
            }
        }
    }
}

#[no_mangle]
pub fn bridge_main() {
    bridge::register(ZygiskCompat::new());
}