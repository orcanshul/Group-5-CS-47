"use client";

import clsx, { ClassValue } from "clsx";
import Marquee from "react-fast-marquee";
import { twMerge } from "tailwind-merge";

function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

type LogosDoubleRowStaticLogo = Logo & {
  href?: string;
};
interface Logo {
  src: string;
  alt: string;
  srcDark?: string;
  className?: string;
}

interface LogosDoubleRowStaticProps {
  heading: string;
  subtitle?: string;
  topRow: LogosDoubleRowStaticLogo[];
  bottomRow: LogosDoubleRowStaticLogo[];
  className?: string;
}

type Props = Partial<LogosDoubleRowStaticProps>;

const defaultProps: LogosDoubleRowStaticProps = {
  heading: "Used by these companies",
  subtitle: "Used by the world's leading teams & startups",
  topRow: [
    {
      src: "https://gpt-research.org/_nuxt/logo.df932ff9.webp",
      alt: "Company logo 1",
      className: "h-7 w-auto",
      href: "",
    },
    {
      src: "https://deifkwefumgah.cloudfront.net/shadcnblocks/image-set/placeholder/logos/fictional-company-logo-2.svg",
      alt: "Company logo 2",
      className: "h-7 w-auto",
      href: "",
    },
    {
      src: "https://deifkwefumgah.cloudfront.net/shadcnblocks/image-set/placeholder/logos/fictional-company-logo-3.svg",
      alt: "Company logo 3",
      className: "h-7 w-auto",
      href: "",
    },
    {
      src: "https://deifkwefumgah.cloudfront.net/shadcnblocks/image-set/placeholder/logos/fictional-company-logo-4.svg",
      alt: "Company logo 4",
      className: "h-7 w-auto",
      href: "",
    },
  ],
  bottomRow: [
    {
      src: "https://deifkwefumgah.cloudfront.net/shadcnblocks/image-set/placeholder/logos/fictional-company-logo-5.svg",
      alt: "Company logo 5",
      className: "h-5 w-auto",
      href: "",
    },
    {
      src: "https://deifkwefumgah.cloudfront.net/shadcnblocks/image-set/placeholder/logos/fictional-company-logo-6.svg",
      alt: "Company logo 6",
      className: "h-7 w-auto",
      href: "",
    },
    {
      src: "https://deifkwefumgah.cloudfront.net/shadcnblocks/image-set/placeholder/logos/fictional-company-logo-7.svg",
      alt: "Company logo 7",
      className: "h-7 w-auto",
      href: "",
    },
    {
      src: "https://deifkwefumgah.cloudfront.net/shadcnblocks/image-set/placeholder/logos/fictional-company-logo-8.svg",
      alt: "Company logo 8",
      className: "h-7 w-auto",
      href: "",
    },
    {
      src: "https://deifkwefumgah.cloudfront.net/shadcnblocks/image-set/placeholder/logos/fictional-company-logo-9.svg",
      alt: "Company logo 9",
      className: "h-7 w-auto",
      href: "",
    },
  ],
};

const Logos25 = (props: Props) => {
  const { heading, subtitle, topRow, bottomRow, className } = {
    ...defaultProps,
    ...props,
  };

  return (
    <section className={cn("overflow-hidden py-4", className)}>
      <div className="mx-auto max-w-5xl px-4">
        <div className="text-center">
          <h2 className="text-sm font-semibold tracking-tight text-balance">
            {heading}
          </h2>
          {subtitle ? (
            <p className="mt-1 text-xs text-[var(--muted)]">{subtitle}</p>
          ) : null}
        </div>

        <div className="mt-3 flex w-full flex-col gap-3">
          <MarqueeRow logos={topRow} direction="left" />
          <MarqueeRow logos={bottomRow} direction="right" />
        </div>
      </div>
    </section>
  );
};

function MarqueeRow({
  logos,
  direction,
}: {
  logos: LogosDoubleRowStaticLogo[];
  direction: "left" | "right";
}) {
  return (
    <div className="relative w-full">
      <Marquee direction={direction} speed={40} pauseOnHover autoFill>
        {logos.map((logo, index) => (
          <div
            key={`${direction}-${logo.src}-${index}`}
            className="mx-8 flex aspect-[3/1] w-28 items-center justify-center sm:w-32 lg:mx-10"
          >
            <img
              src={logo.src}
              alt={logo.alt}
              className={cn(
                logo.className,
                "h-auto max-h-7 w-auto object-contain dark:invert",
              )}
            />
          </div>
        ))}
      </Marquee>
      <div className="pointer-events-none absolute inset-y-0 left-0 z-10 w-16 bg-gradient-to-r from-[#0f0804] to-transparent" />
      <div className="pointer-events-none absolute inset-y-0 right-0 z-10 w-16 bg-gradient-to-l from-[#0f0804] to-transparent" />
    </div>
  );
}

export { Logos25 };