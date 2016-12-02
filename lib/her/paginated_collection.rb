module Her
  class PaginatedCollection
    include Enumerable

    # Required pagination methods: current_page, per_page, offset, total_entries, total_pages
    attr_reader :current_page, :per_page, :metadata, :errors

    def initialize(items: [], metadata: {}, errors: {}, links: {}, current_page:, per_page:)
      raise ArgumentError.new("current_page must be positive") if current_page < 1
      raise ArgumentError.new("per_page must be positive") if per_page < 1

      @links = links
      @current_page = current_page
      @per_page = per_page
      @items = items
      @metadata = metadata
      @errors = errors
    end

    def offset
      ((current_page - 1) * per_page).to_i
    end

    def total_entries
      # It would be better if we had actual info. This could come in the response
      # from the service something like {meta: {totalPages: 200, totalEntries: 3987}}
      # But since we don't currently, use a rough guess based on total_pages
      @total_entries ||= if current_page == total_pages
        # On the last page we know the actual total
        (total_pages - 1) * per_page + size
      else
        # Take a guess based on number of pages
        # Guess that the last page will be half full
        (total_pages - 1) * per_page + per_page / 2
      end
    end

    def total_pages
      # Parse this info out of the links. This would be better coming from a meta section
      # e.g., {meta: {totalPages: 404}}
      @total_pages ||= if @links["last"].present?
        @links["last"].match(/page%5Bnumber%5D=(\d+)/)[1].to_i
      elsif @links["self"].present? # Last link isn't available when on the last page
        @links["self"].match(/page%5Bnumber%5D=(\d+)/)[1].to_i
      else
        1
      end
    end

    # optional pagination methods: out_of_bounds?, previous_page, next_page
    def out_of_bounds?
      current_page > total_pages
    end

    def previous_page
      return nil unless current_page > 1
      current_page - 1
    end

    def next_page
      return nil unless current_page < total_pages
      current_page + 1
    end

    # Collection methods
    delegate :<<, :each, :size, :to_ary, :to_a, :sort_by!, :empty?, to: :items

    private

    attr_reader :items
  end
end
