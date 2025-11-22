require "rails_helper"

RSpec.describe TimeConverter do
  describe ".sc_to_lc" do
    context "with 100m Freestyle" do
      it "converts SC time to LC time correctly" do
        sc_time = 60.0 # 1:00.00
        lc_time = described_class.sc_to_lc(sc_time, 100, "FREE")

        # LC should be slower (higher time) than SC
        expect(lc_time).to be > sc_time
        # British Swimming algorithm gives ~1.38 seconds difference for 60s 100m Free
        expect(lc_time).to be_within(0.1).of(61.38)
      end
    end

    context "with 200m Breaststroke" do
      it "converts SC time to LC time correctly" do
        sc_time = 150.0 # 2:30.00
        lc_time = described_class.sc_to_lc(sc_time, 200, "BREAST")

        expect(lc_time).to be > sc_time
        # Breaststroke has larger conversion difference due to underwater pullouts
        expect(lc_time).to be_within(1.0).of(153.5)
      end
    end

    context "with 50m events" do
      it "converts with minimal difference due to fewer turns" do
        sc_time = 30.0
        lc_time = described_class.sc_to_lc(sc_time, 50, "FREE")

        expect(lc_time).to be > sc_time
        # 50m has less difference due to only one turn, ~0.69 seconds for 30s time
        expect(lc_time - sc_time).to be < 1.0
        expect(lc_time - sc_time).to be > 0.5
      end
    end

    context "with 400m IM" do
      it "converts SC time to LC time correctly" do
        sc_time = 300.0 # 5:00.00
        lc_time = described_class.sc_to_lc(sc_time, 400, "IM")

        expect(lc_time).to be > sc_time
        expect(lc_time).to be_within(2.0).of(305.0)
      end
    end

    context "with unsupported event" do
      it "returns the original time when no turn factor exists" do
        sc_time = 120.0
        lc_time = described_class.sc_to_lc(sc_time, 400, "BREAST")

        # No turn factor for 400m Breaststroke, should return original
        expect(lc_time).to eq(sc_time)
      end
    end

    context "with nil time" do
      it "returns nil" do
        expect(described_class.sc_to_lc(nil, 100, "FREE")).to be_nil
      end
    end

    context "with zero or negative time" do
      it "returns the original value for zero" do
        expect(described_class.sc_to_lc(0, 100, "FREE")).to eq(0)
      end

      it "returns the original value for negative" do
        expect(described_class.sc_to_lc(-1, 100, "FREE")).to eq(-1)
      end
    end
  end

  describe ".lc_to_sc" do
    context "with 100m Freestyle" do
      it "converts LC time to SC time correctly" do
        lc_time = 60.0 # 1:00.00
        sc_time = described_class.lc_to_sc(lc_time, 100, "FREE")

        # SC should be faster (lower time) than LC
        expect(sc_time).to be < lc_time
        # British Swimming algorithm gives ~1.41 seconds difference for 60s 100m Free
        expect(sc_time).to be_within(0.1).of(58.59)
      end
    end

    context "with 200m Butterfly" do
      it "converts LC time to SC time correctly" do
        lc_time = 140.0 # 2:20.00
        sc_time = described_class.lc_to_sc(lc_time, 200, "FLY")

        expect(sc_time).to be < lc_time
        expect(sc_time).to be_within(1.0).of(138.0)
      end
    end

    context "with 1500m Freestyle" do
      it "converts LC time to SC time correctly" do
        lc_time = 1000.0 # 16:40.00
        sc_time = described_class.lc_to_sc(lc_time, 1500, "FREE")

        expect(sc_time).to be < lc_time
        # 1500m has significant difference due to many turns
        expect(lc_time - sc_time).to be > 5.0
      end
    end

    context "with unsupported event" do
      it "returns the original time when no turn factor exists" do
        lc_time = 120.0
        sc_time = described_class.lc_to_sc(lc_time, 400, "BACK")

        # No turn factor for 400m Backstroke, should return original
        expect(sc_time).to eq(lc_time)
      end
    end

    context "with nil time" do
      it "returns nil" do
        expect(described_class.lc_to_sc(nil, 100, "FREE")).to be_nil
      end
    end
  end

  describe "bidirectional conversion" do
    it "converts SC -> LC -> SC with minimal loss" do
      original_sc = 60.0
      lc = described_class.sc_to_lc(original_sc, 100, "FREE")
      back_to_sc = described_class.lc_to_sc(lc, 100, "FREE")

      # Should be very close to original (within 0.01 seconds)
      expect(back_to_sc).to be_within(0.01).of(original_sc)
    end

    it "converts LC -> SC -> LC with minimal loss" do
      original_lc = 60.0
      sc = described_class.lc_to_sc(original_lc, 100, "FREE")
      back_to_lc = described_class.sc_to_lc(sc, 100, "FREE")

      # Should be very close to original (within 0.01 seconds)
      expect(back_to_lc).to be_within(0.01).of(original_lc)
    end
  end

  describe ".get_time_for_course" do
    it "returns LC time when requested" do
      expect(described_class.get_time_for_course(60.0, 59.0, "LC")).to eq(60.0)
    end

    it "returns SC time when requested" do
      expect(described_class.get_time_for_course(60.0, 59.0, "SC")).to eq(59.0)
    end

    it "returns LC time as default when course not specified" do
      expect(described_class.get_time_for_course(60.0, 59.0, nil)).to eq(60.0)
    end

    it "returns SC time when LC is nil" do
      expect(described_class.get_time_for_course(nil, 59.0, nil)).to eq(59.0)
    end
  end
end
