#![feature(try_blocks)]
#![feature(duration_constructors)]

mod loader;
mod macros;
mod monitor;
mod symbols;

use public::{
    debug_select,
    utils::dump_tombstone_on_panic
};

use clap::Parser;
use log::LevelFilter;

#[derive(Parser, Debug)]
struct Args {
    #[clap(short, long)]
    filter: bool
}

fn init_logger() {
    android_logger::init_once(
        android_logger::Config::default()
            .with_max_level(debug_select!(LevelFilter::Trace, LevelFilter::Info))
            .with_tag("ZLoader-Core")
    );
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    init_logger();
    dump_tombstone_on_panic();

    let args = Args::parse();

    let filter_path = if args.filter {
        Some("/data/adb/modules/zloadersu/lib/libloader.so")
    } else {
        None
    };

    monitor::main(filter_path).await?;

    Ok(())
}
