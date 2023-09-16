module ethernetframe(
    input clk,
    input signal, //input signal
    output  reg done, // process have done
    output reg [12000:0] data_sorted_final //information data
);
reg [3:0] state,next_state;
parameter s1=0; // use for fsm
parameter s2=1; // use for fsm
parameter s3=2; // use for fsm
parameter s4=3; // use for fsm
parameter s5=4; // use for fsm
parameter s6=5; // use for fsm
parameter s7=6; // use for fsm
parameter s8=7; // use for fsm
parameter s9=8; // use for fsm
reg i=0; // i has been used to check preamble
reg j=1; // j has been used to check sfd
reg [47:0] mac_destination; 
reg mac_destination_stat=0; // to find out did we deteact mac_destination
reg [47:0] mac_source;
reg mac_source_stat=0; // to find out did we deteact mac_source
reg mac_type[15:0];
reg mac_type_stat=0; // to find out did we deteact data_length
reg [12000:0] data; // to save data
reg [12000:0] data_sorted; // to save data
reg get_fcs=0; // we are ready to fet fcs
reg sort_data=0; // we are ready to sort data
reg final_check=0; // we are ready to error detection
reg error_bit=0; // do we have error?
wire [32:0] poly=2'b100000100010000010001110110110111; //crc-32 standard polly
reg done1=0; // we are done
reg len=0; // length of data
reg remain=0; // remain of crc32 alghoritm
integer counter; // for for loops
integer counter_2; // for for loops
always @(posedge clk) begin
    if(i!=7) begin //fsm to get 7 times 10101010
        state<=next_state;
        case(state) 
            s1: begin 
                if(signal)
                    next_state=s2;
                else begin
                    next_state=s1;
                end
            end
            s2: begin
                if(!signal)
                    next_state=s3;
                else begin
                    next_state=s1;
                    i=0;
                end
            end
            s3: begin
                if(signal)
                    next_state=s4;
                else begin
                    next_state=s1;
                    i=0;
                end
             end
            s4: begin
                if(!signal)
                     next_state=s5;
                else begin
                      next_state=s1;
                    i=0;
                end
            end
            s5:begin
                if(signal)
                    next_state=s6;
                 else begin
                    next_state=s1;
                     i=0;
                 end
            end
            s6:begin
                if(!signal)
                    next_state=s7;
                else begin
                     next_state=s1;
                    i=0;
                 end
            end
            s7:begin
                if(signal)
                    next_state=s8;
                else begin
                    next_state=s1;
                     i=0;
                end
            end
            s8:begin
                 if(!signal)
                     next_state=s9;
                 else begin
                     next_state=s1;
                     i=0;
                end
            end
            s9:begin
                 if(signal) begin
                    i=i+1;
                    next_state=s2;
                    if(i==7)
                        next_state=s1;
                end
                else begin
                    next_state=s1;
                    i=0;
                 end
             end
        endcase
    end
    if(i==7 && j!=1) begin // fsm to get 10101011
        next_state<=signal;
        state<=next_state;
        case(state) 
            s1: begin
                if(next_state==1)
                    next_state=s2;
                else begin
                    next_state=s1;
                    i=0;
                end
            end
            s2: begin
                if(next_state==0)
                    next_state=s3;
                else begin
                    next_state=s1;
                    i=0;
                end
            end
            s3: begin
                if(next_state==1)
                    next_state=s4;
                else begin
                    next_state=s1;
                i=0;
                end
            end
            s4: begin
                if(next_state==0)
                    next_state=s5;
                else begin
                    next_state=s1;
                    i=0;
                end
            end
            s5:begin
                if(next_state==1)
                    next_state=s6;
                else begin
                    next_state=s1;
                    i=0;
                end
            end
            s6:begin
                if(next_state==0)
                    next_state=s7;
                 else begin
                    next_state=s1;
                    i=0;
                end
            end
            s7:begin
                if(next_state==1)
                    next_state=s8;
                else begin
                    next_state=s1;
                    i=0;
                end
            end
            s8:begin
                if(next_state==1)
                    next_state=s9;
                else begin
                    next_state=s1;
                    i=0;
                end
            end
            s9:begin
                j=1;
                next_state=s1;
            end
        endcase
    end 
        if(!mac_destination_stat) begin //get mac_destination
            for(counter=0;counter<48;counter=counter+1) begin
                mac_destination[counter]=signal;
                if(counter==47)
                    mac_destination_stat=1;
            end
        end
        else if(!mac_source_stat) begin // get mac source 
            for(counter=0;counter<48;counter=counter+1) begin
                mac_source[counter]=signal;
                if(counter==47)
                    mac_source_stat=1;
            end
        end
        else if(!mac_type_stat) begin //get ethertype
            for(counter=0;counter<15;counter=counter+1) begin
                mac_type[counter]=signal;
                if(counter==15)
                    mac_type_stat=1;
                    for(counter_2=0;counter_2<16;counter_2=counter_2+1) begin
                        len=len+(2**(15-counter_2));
                    end
            end
        end
        if(mac_type_stat)begin //get data
            for(counter=0;counter<len;counter=counter+1)begin
                data[counter]=signal;
                if(counter==len-1)
                    get_fcs=1;
            end
        end
        if(get_fcs)begin //get fcs
            for(counter=0;counter<32;counter=counter+1) begin
                data[len+counter]=signal;
                if(counter==31)
                    sort_data=1;
            end
        end
        if(sort_data)begin //sort data
            for(counter=0;counter<len+32;counter=counter+1) begin
                data_sorted[counter]=data[len+32-counter];//sort data from up to down
            end
            for(counter=0;counter<12000;counter=counter+1)begin
                data_sorted[counter+len+32]=0;//sort data from up to down
            end
            final_check=1;
        end
        if(final_check) begin //final check
            error_bit=(data_sorted) % (poly);
            if(error_bit!=0)begin
                for(counter_2=0;counter_2<len+32;counter_2=counter_2+1) begin
                    data_sorted[counter_2]=~data_sorted[counter_2];
                    remain=data_sorted % poly; // if remain is zero it's ok
                    if(remain==0)
                        counter_2=100;// to breal
                    else begin
                        data_sorted[counter_2]=~data_sorted[counter_2];
                    end
                end
            end
            done1=1;
        end
    end
    data_sorted_final=data_sorted;
    done=1;
end
endmodule
