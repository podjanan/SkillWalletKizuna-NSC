// components/admin/Pagination.tsx

interface PaginationProps {
  currentPage: number;
  totalPages: number;
  total: number;
  pageSize: number;
  itemCount: number;
  onPageChange: (page: number) => void;
}

export default function Pagination({
  currentPage,
  totalPages,
  total,
  pageSize,
  itemCount,
  onPageChange,
}: PaginationProps) {
  const from = total > 0 ? (currentPage - 1) * pageSize + 1 : 0;
  const to = (currentPage - 1) * pageSize + itemCount;

  // สร้างรายการเลขหน้าพร้อม ellipsis
  const getPages = (): (number | '...')[] => {
    if (totalPages <= 7) {
      return Array.from({ length: totalPages }, (_, i) => i + 1);
    }

    const pages: (number | '...')[] = [1];

    if (currentPage > 3) pages.push('...');

    const start = Math.max(2, currentPage - 1);
    const end = Math.min(totalPages - 1, currentPage + 1);
    for (let i = start; i <= end; i++) pages.push(i);

    if (currentPage < totalPages - 2) pages.push('...');

    pages.push(totalPages);
    return pages;
  };

  return (
    <div className="flex items-center justify-between px-6 py-4 border-t border-gray4">
      <div className="body-small-regular text-secondary--text">
        Showing {from} to {to} of {total} results
      </div>

      <div className="flex items-center gap-1">
        <button
          onClick={() => onPageChange(currentPage - 1)}
          disabled={currentPage === 1}
          className="px-3 py-1 body-small-medium text-secondary--text hover:bg-gray--light1 rounded disabled:opacity-40 disabled:cursor-not-allowed"
        >
          Previous
        </button>

        {getPages().map((page, i) =>
          page === '...' ? (
            <span key={`ellipsis-${i}`} className="px-2 body-small-medium text-secondary--text">
              ...
            </span>
          ) : (
            <button
              key={page}
              onClick={() => onPageChange(page as number)}
              className={`px-3 py-1 body-small-medium rounded ${
                currentPage === page
                  ? 'bg-purple text-white'
                  : 'text-secondary--text hover:bg-gray--light1'
              }`}
            >
              {page}
            </button>
          )
        )}

        <button
          onClick={() => onPageChange(currentPage + 1)}
          disabled={currentPage === totalPages || totalPages === 0}
          className="px-3 py-1 body-small-medium text-secondary--text hover:bg-gray--light1 rounded disabled:opacity-40 disabled:cursor-not-allowed"
        >
          Next
        </button>
      </div>
    </div>
  );
}
