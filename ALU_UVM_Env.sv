package UVMpackage;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    //////////////////////////////Transaction///////////////////////////
    class my_sequence_item extends uvm_sequence_item;
    `uvm_object_utils(my_sequence_item);
    function new(string name = "my_sequence_item");
        super.new(name);
    endfunction
    rand logic [4:0] ALU_A;
    rand logic [4:0] ALU_B;
    rand logic enable;
    rand logic [1:0] select;
    logic signed [5:0] out;
    logic [12:0] operands;
    constraint constr1{
        enable dist {1:=5,0:=2};
        select dist {0:=2,1:=2,2:=1,3:=1};
        ALU_B inside {[0:10]};
    }
    endclass
                  /////////////////Objects///////////// 
    ///////////////////////////////Sequence/////////////////////////////
    class my_sequence extends uvm_sequence;
    `uvm_object_utils(my_sequence);
    my_sequence_item seq_item;
    function new(string name = "my_sequence");
        super.new(name);
    endfunction
    task pre_body();
        seq_item = my_sequence_item::type_id::create("seq_item");
    endtask
    task body();
    for(int i = 0; i < 300; i++) begin
        start_item(seq_item);
        if( !seq_item.randomize() )
				`uvm_error(get_type_name(), "Failed to randomize sequence_items")
        finish_item(seq_item);
    end
    endtask
    endclass
                  ////////////////Components/////////// 
    ///////////////////////////////Sequencer//////////////////////////////
    class my_sequencer extends uvm_sequencer #(my_sequence_item);
    `uvm_component_utils(my_sequencer);//factory Registration
    function new(string name="my_sequencer",uvm_component parent = null);
        super.new(name,parent);
    endfunction
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
    endfunction
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction
    task run_phase(uvm_phase phase);
            super.run_phase(phase);
    endtask
    endclass
    /////////////////////////////Driver///////////////////////////////////
    class my_driver extends uvm_driver#(my_sequence_item);
    `uvm_component_utils(my_driver);//factory Registration
    my_sequence_item seq_item_driver;
    virtual ALU_in_if mydriver_ALU_in_if;
    uvm_analysis_port #(my_sequence_item) driver_port;
    function new(string name="my_driver",uvm_component parent = null);
        super.new(name,parent);
    endfunction
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        driver_port = new("driver_port",this);
        seq_item_driver = my_sequence_item::type_id::create("seq_item_driver");
        if(!uvm_config_db#(virtual ALU_in_if)::get(this,"","ALU_in_vif",mydriver_ALU_in_if))
            `uvm_fatal(get_full_name(),"Error getting input interface in my active agent");
    endfunction
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction
    task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
            seq_item_port.get_next_item(seq_item_driver);
            @(posedge mydriver_ALU_in_if.clk) begin
                mydriver_ALU_in_if.ALU_A <= seq_item_driver.ALU_A;
                mydriver_ALU_in_if.ALU_B <= seq_item_driver.ALU_B;
                mydriver_ALU_in_if.select <= seq_item_driver.select;
                mydriver_ALU_in_if.enable <= seq_item_driver.enable;
            end
            seq_item_port.item_done(seq_item_driver);
            driver_port.write(seq_item_driver); //to subscriber
        end
        endtask
    endclass
    //////////////////////////////DUT_Monitor/////////////////////////////
    class DUT_out_monitor extends uvm_monitor;
    `uvm_component_utils(DUT_out_monitor);//factory Registration
    my_sequence_item seq_item_DUT_out;
    virtual ALU_out_if mymonitor_ALU_DUT_out_if;
    uvm_blocking_put_port #(my_sequence_item) DUT_mon_port;

    function new(string name="DUT_monitor",uvm_component parent = null);
        super.new(name,parent);
    endfunction
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        seq_item_DUT_out = my_sequence_item::type_id::create("seq_item_DUT_out");
        if(!uvm_config_db #(virtual ALU_out_if)::get(this,"","ALU_DUT_out_vif",mymonitor_ALU_DUT_out_if))
            `uvm_fatal(get_full_name(),"Error getting DuT out virtual interface in my DUT monitor");
        DUT_mon_port = new("DUT_mon_port",this);
    endfunction
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction
    task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                @(posedge mymonitor_ALU_DUT_out_if.clk)
                    seq_item_DUT_out.out <= mymonitor_ALU_DUT_out_if.out;
                    seq_item_DUT_out.operands <= mymonitor_ALU_DUT_out_if.operands;
                    DUT_mon_port.put(seq_item_DUT_out);
            end
        endtask
    endclass
    //////////////////////////REF_model_Monitor///////////////////////////
    class REF_out_monitor extends uvm_monitor;
    `uvm_component_utils(REF_out_monitor);//factory Registration
    my_sequence_item seq_item_REF_out;
    virtual ALU_out_if mymonitor_ALU_REF_out_if;
    uvm_blocking_put_port #(my_sequence_item) REF_mon_port;
    function new(string name="REF_monitor",uvm_component parent = null);
        super.new(name,parent);
    endfunction
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        seq_item_REF_out = my_sequence_item::type_id::create("seq_item_REF_out");
        if(!uvm_config_db #(virtual ALU_out_if)::get(this,"","ALU_REF_out_vif",mymonitor_ALU_REF_out_if))
            `uvm_fatal(get_full_name(),"Error getting Ref out virtual interface in my REF monitor");
        REF_mon_port = new("REF_mon_port",this);
    endfunction
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction
    task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                @(posedge mymonitor_ALU_REF_out_if.clk)
                    seq_item_REF_out.out <= mymonitor_ALU_REF_out_if.out;
                    seq_item_REF_out.operands <= mymonitor_ALU_REF_out_if.operands;
                    REF_mon_port.put(seq_item_REF_out);
            end
           
        endtask
    endclass
    ////////////////////////////Agents//////////////////////////////////
    class Active_agent extends uvm_agent;
    `uvm_component_utils(Active_agent);//factory Registration
    my_driver driver1;
    my_sequencer sequencer1;
    virtual ALU_in_if myagent_ALU_in_if;
    my_sequence_item seq_item;
    function new(string name="Active_agent",uvm_component parent = null);
        super.new(name,parent);
    endfunction
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        driver1 = my_driver::type_id::create("driver1",this);
        sequencer1 = my_sequencer::type_id::create("sequencer1",this);
        if(!uvm_config_db#(virtual ALU_in_if)::get(this,"","ALU_in_vif",myagent_ALU_in_if))
            `uvm_fatal(get_full_name(),"Error getting input interface in my active agent");
        uvm_config_db#(virtual ALU_in_if)::set(this,"driver1","ALU_in_vif",myagent_ALU_in_if);
    endfunction
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver1.seq_item_port.connect(sequencer1.seq_item_export);
    endfunction
    task run_phase(uvm_phase phase);
            super.run_phase(phase);
    endtask
    endclass 

    class passive_agent extends uvm_agent;
    `uvm_component_utils(passive_agent);//factory Registration
    virtual ALU_out_if myagent_ALU_DUT_out_if;
    virtual ALU_out_if myagent_ALU_REF_out_if;
    DUT_out_monitor DUT_out_mon;
    REF_out_monitor REF_out_mon;
    
    uvm_blocking_put_port#(my_sequence_item) DUT_port;
    uvm_blocking_put_port#(my_sequence_item) REF_port;

    function new(string name="passive_agent",uvm_component parent = null);
        super.new(name,parent);
    endfunction
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        DUT_out_mon = DUT_out_monitor::type_id::create("DUT_out_mon",this);
        REF_out_mon = REF_out_monitor::type_id::create("REF_out_mon",this);
        DUT_port = new("DUT_port",this);
        REF_port = new("REF_port",this);
        if(!uvm_config_db #(virtual ALU_out_if)::get(this,"","ALU_DUT_out_vif",myagent_ALU_DUT_out_if))
            `uvm_fatal(get_full_name(),"Error getting DuT out virtual interface in my passive agent");
        uvm_config_db #(virtual ALU_out_if)::set(this,"DUT_out_mon","ALU_DUT_out_vif",myagent_ALU_DUT_out_if);

        if(!uvm_config_db #(virtual ALU_out_if)::get(this,"","ALU_REF_out_vif",myagent_ALU_REF_out_if))
            `uvm_fatal(get_full_name(),"Error getting Ref out virtual interface in my passive agent");
        uvm_config_db #(virtual ALU_out_if)::set(this,"REF_out_mon","ALU_REF_out_vif",myagent_ALU_REF_out_if);
    endfunction
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        DUT_out_mon.DUT_mon_port.connect(this.DUT_port);
        REF_out_mon.REF_mon_port.connect(this.REF_port);
    endfunction
    task run_phase(uvm_phase phase);
            super.run_phase(phase);
        endtask
    endclass
    ///////////////////////////Scoreboard///////////////////////////////
    class my_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(my_scoreboard);//factory Registration
    my_sequence_item DUT_out_item,REF_out_item;
    uvm_blocking_get_port#(my_sequence_item) DUT_port,REF_port;
    int count =0;
    function new(string name="my_scoreboard",uvm_component parent = null);
        super.new(name,parent);
    endfunction
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        DUT_port = new("DUT_port",this);
        REF_port = new("REF_port",this);
    endfunction
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    function string operation (logic [1:0] select);
        case(select)
                        2'b00 : operation = "Addition";
                        2'b01 : operation = "subtraction";
                        2'b10 : operation = "shift right";
                        2'b11 : operation = "shift left";
        endcase
    endfunction
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            DUT_port.get(DUT_out_item);
            REF_port.get(REF_out_item);
            count = count +1;
        if(count >=3) begin
            if(DUT_out_item.out == REF_out_item.out )
				begin
					$display("Input from Driver T=%0t ALU_A = %0d ALU_B = %0d Operation = \"%0s\" Enable = %0d",$time,DUT_out_item.operands[12:8],DUT_out_item.operands[7:3],operation(DUT_out_item.operands[1:0]),DUT_out_item.operands[2]);
                    #5;
                    $display("OUTPUT FROM DUT        T=%0t OUT = %0d", $time , DUT_out_item.out);
                    $display("OUTPUT FROM REF MODEL  T=%0t OUT = %0d", $time , REF_out_item.out);
                    $display("PASS , matching values");
                    #5;
				end
				else
					$display("ERROR , Unmatching values");
        end

		end
    endtask
    endclass
    ///////////////////////////subscriber///////////////////////////////
    class my_subscriber extends uvm_subscriber#(my_sequence_item);			
	`uvm_component_utils(my_subscriber);
	my_sequence_item m_seq;
	covergroup group_1;
		point_1: coverpoint m_seq.ALU_A{
			bins bin_1[] = {[0:$]};
		}
		point_2: coverpoint  m_seq.ALU_B{
			bins bin_2[] = {[0:$]};
		} 
		point_4: coverpoint  m_seq.select{
            bins bin_4[] = {[0:$]};
        }
        point_3: coverpoint  m_seq.enable{
			bins bin_3[] = {[0:1]};
		}
		cross_1: cross point_1, point_3;
		cross_2: cross point_2, point_3;
	endgroup 

	function new (string name = "my_subscriber" , uvm_component parent = null);
		super.new(name,parent);
		group_1 = new();
	endfunction : new
	function void build_phase (uvm_phase phase);
		super.build_phase(phase);
		m_seq = my_sequence_item::type_id::create("m_seq");
	endfunction : build_phase
	function void connect_phase (uvm_phase phase);
		super.connect_phase(phase);
	endfunction : connect_phase

	function void write (my_sequence_item t);
		m_seq = t;
		group_1.sample();
	endfunction : write
 
	endclass
    ///////////////////////////Environment//////////////////////////////
    class my_env extends uvm_env;
    `uvm_component_utils(my_env);//factory Registration
    my_scoreboard scoreboard1;
    my_subscriber subscriber1;
    Active_agent Agent_in;
    passive_agent Agent_out;

    virtual ALU_in_if myenv_ALU_in_if;
    virtual ALU_out_if myenv_ALU_DUT_out_if;
    virtual ALU_out_if myenv_ALU_REF_out_if;

    uvm_tlm_fifo#(my_sequence_item) my_comparing_fifo;

    function new(string name="my_env",uvm_component parent = null);
        super.new(name,parent);
    endfunction
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        my_comparing_fifo = new("my_comparing_fifo",this,5);
        scoreboard1 = my_scoreboard::type_id::create("scoreboard1",this);
        subscriber1 = my_subscriber::type_id::create("subscriber1",this);
        Agent_in  = Active_agent::type_id::create("Agent_in",this);
        Agent_out = passive_agent::type_id::create("Agent_out",this);

        if(!uvm_config_db #(virtual ALU_in_if)::get(this,"","ALU_in_vif",myenv_ALU_in_if))
            `uvm_fatal(get_full_name(),"Error getting input virtual interface in my env");
        uvm_config_db #(virtual ALU_in_if)::set(this,"Agent_in","ALU_in_vif",myenv_ALU_in_if);
        if(!uvm_config_db #(virtual ALU_out_if)::get(this,"","ALU_DUT_out_vif",myenv_ALU_DUT_out_if))
            `uvm_fatal(get_full_name(),"Error getting DuT out virtual interface in my env");
        uvm_config_db #(virtual ALU_out_if)::set(this,"Agent_out","ALU_DUT_out_vif",myenv_ALU_DUT_out_if);
        if(!uvm_config_db #(virtual ALU_out_if)::get(this,"","ALU_REF_out_vif",myenv_ALU_REF_out_if))
            `uvm_fatal(get_full_name(),"Error getting Ref out virtual interface in my env");
        uvm_config_db #(virtual ALU_out_if)::set(this,"Agent_out","ALU_REF_out_vif",myenv_ALU_REF_out_if);
    endfunction
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        //connecting TLM
        Agent_out.DUT_port.connect(my_comparing_fifo.put_export);
        Agent_out.REF_port.connect(my_comparing_fifo.put_export);
        scoreboard1.REF_port.connect(my_comparing_fifo.get_export);
        scoreboard1.DUT_port.connect(my_comparing_fifo.get_export);
        Agent_in.driver1.driver_port.connect(subscriber1.analysis_export);
    endfunction
    task run_phase(uvm_phase phase);
            super.run_phase(phase);
        endtask
    endclass
    ///////////////////////////Test/////////////////////////////////////
    class my_test extends uvm_test;
    `uvm_component_utils(my_test);//factory Registration
    my_env env1;
    my_sequence sequence1;
    virtual ALU_in_if mytest_ALU_in_if;
    virtual ALU_out_if mytest_ALU_DUT_out_if;
    virtual ALU_out_if mytest_ALU_REF_out_if;
    function new(string name="my_test",uvm_component parent = null);
        super.new(name,parent);
    endfunction
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        env1 = my_env::type_id::create("env1",this);
        sequence1 = my_sequence::type_id::create("sequence1",this);
        if(!uvm_config_db #(virtual ALU_in_if)::get(this,"","ALU_in_vif",mytest_ALU_in_if))
            `uvm_fatal(get_full_name(),"Error getting input virtual interface in my test");
        uvm_config_db #(virtual ALU_in_if)::set(this,"env1","ALU_in_vif",mytest_ALU_in_if);
        if(!uvm_config_db #(virtual ALU_out_if)::get(this,"","ALU_DUT_out_vif",mytest_ALU_DUT_out_if))
            `uvm_fatal(get_full_name(),"Error getting DuT out virtual interface in my test");
        uvm_config_db #(virtual ALU_out_if)::set(this,"env1","ALU_DUT_out_vif",mytest_ALU_DUT_out_if);
        if(!uvm_config_db #(virtual ALU_out_if)::get(this,"","ALU_REF_out_vif",mytest_ALU_REF_out_if))
            `uvm_fatal(get_full_name(),"Error getting Ref out virtual interface in my test");
        uvm_config_db #(virtual ALU_out_if)::set(this,"env1","ALU_REF_out_vif",mytest_ALU_REF_out_if);
    endfunction
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction
    task run_phase(uvm_phase phase);
            super.run_phase(phase);
            sequence1.set_response_queue_depth(-1);
            phase.raise_objection(this);
                sequence1.start(env1.Agent_in.sequencer1); //5ally el driver y communicate ma3 el sequencer
                #200
            phase.drop_objection(this);
        endtask
    endclass


endpackage
///////////////////////////////
module UVM_Top;
    import UVMpackage::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh";
    ALU_in_if my_ALU_in_if();
    ALU_out_if ALU_DUT_out_if();
    ALU_out_if ALU_REF_out_if();

    ALU ALU_DUT(my_ALU_in_if,ALU_DUT_out_if);
    ALU_Ref_model ALU_REF(my_ALU_in_if,ALU_REF_out_if);
    initial begin
        my_ALU_in_if.clk = 0;
        my_ALU_in_if.rst = 0;
        #1 my_ALU_in_if.rst = 1;
        #1 my_ALU_in_if.rst = 0;
    end
    always #5 my_ALU_in_if.clk = ~my_ALU_in_if.clk;

    assign ALU_DUT_out_if.clk = my_ALU_in_if.clk;
    assign ALU_REF_out_if.clk = my_ALU_in_if.clk;
    assign ALU_DUT_out_if.operands = {my_ALU_in_if.ALU_A,my_ALU_in_if.ALU_B,my_ALU_in_if.enable,my_ALU_in_if.select};

    initial begin
    uvm_config_db #(virtual ALU_in_if)::set(null,"uvm_test_top","ALU_in_vif",my_ALU_in_if);
    uvm_config_db #(virtual ALU_out_if)::set(null,"uvm_test_top","ALU_DUT_out_vif",ALU_DUT_out_if);
    uvm_config_db #(virtual ALU_out_if)::set(null,"uvm_test_top","ALU_REF_out_vif",ALU_REF_out_if);
    run_test("my_test");
    end

endmodule
///////////////////////////////
module ALU(ALU_in_if.ALU_DUT i1,ALU_out_if.ALU_DUT i3);
always@(posedge i1.clk or posedge i1.rst)
begin
    if(i1.rst)begin
        i3.out <= 0;
    end
    else begin
    if(i1.enable)begin
	case(i1.select)
		2'b00: i3.out        <= i1.ALU_A+i1.ALU_B;
		2'b01: i3.out        <= i1.ALU_A-i1.ALU_B;
        2'b10: i3.out        <= i1.ALU_A >> i1.ALU_B;
        2'b11: i3.out        <= i1.ALU_A << i1.ALU_B;
	endcase
    end
    else begin
        i3.out <= 0;
    end
end
end
endmodule
////////////////////////////////////////// 
module ALU_Ref_model(ALU_in_if.ALU_REF i2,ALU_out_if.ALU_REF i4);
always@(posedge i2.clk or posedge i2.rst)
begin
    if(i2.rst)begin
        i4.out <= 0;
    end
    else begin
    if(i2.enable)begin
	case(i2.select)
		2'b00: i4.out        <= i2.ALU_A  + i2.ALU_B;
		2'b01: i4.out        <= i2.ALU_A  - i2.ALU_B;
        2'b10: i4.out        <= i2.ALU_A >> i2.ALU_B;
        2'b11: i4.out        <= i2.ALU_A << i2.ALU_B;
	endcase
    end
    else begin
        i4.out <= 0;
    end
end
end
endmodule
/////////////////////////////
interface ALU_in_if;
logic clk;
logic rst;
logic enable;
logic[1:0] select;
logic[4:0] ALU_A;
logic[4:0] ALU_B;
modport ALU_DUT (
input clk,rst,enable,select,ALU_A,ALU_B
);
modport ALU_REF (
input clk,rst,enable,select,ALU_A,ALU_B
);
endinterface

interface ALU_out_if;
logic signed [5:0] out;
logic signed [12:0] operands;
logic clk;
modport ALU_DUT (
    input clk,
    output out,operands
    );
modport ALU_REF (
    input clk,
    output out,operands
    );
endinterface
