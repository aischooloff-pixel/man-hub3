-- Add unique short code for products
ALTER TABLE public.user_products 
ADD COLUMN IF NOT EXISTS short_code TEXT UNIQUE;

-- Create function to generate product short code
CREATE OR REPLACE FUNCTION public.generate_product_code()
RETURNS TEXT
LANGUAGE plpgsql
SET search_path TO 'public'
AS $function$
DECLARE
  chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..8 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN result;
END;
$function$;

-- Create trigger to auto-generate short_code on insert
CREATE OR REPLACE FUNCTION public.set_product_short_code()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.short_code IS NULL THEN
    LOOP
      NEW.short_code := generate_product_code();
      BEGIN
        -- Check if exists
        PERFORM 1 FROM user_products WHERE short_code = NEW.short_code;
        IF NOT FOUND THEN
          EXIT; -- unique, exit loop
        END IF;
      END;
    END LOOP;
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS set_product_short_code_trigger ON public.user_products;
CREATE TRIGGER set_product_short_code_trigger
  BEFORE INSERT ON public.user_products
  FOR EACH ROW
  EXECUTE FUNCTION public.set_product_short_code();

-- Update existing products with short codes
UPDATE public.user_products 
SET short_code = generate_product_code() 
WHERE short_code IS NULL;

-- Create index for product search
CREATE INDEX IF NOT EXISTS idx_user_products_short_code ON public.user_products(short_code);