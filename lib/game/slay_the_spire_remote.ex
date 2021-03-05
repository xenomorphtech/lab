#Maybe use this later to spin up multiple nodes of the game client with seperate working dirs
defmodule SlayTheSpireRemote do
    @nodename ""

    def run_node() do
    end

    def init() do
        File.mkdir_p!("./priv/slay_the_spire/tmpdir")
        File.cd("./priv/slay_the_spire/tmpdir")
        run_node()
    end
end
